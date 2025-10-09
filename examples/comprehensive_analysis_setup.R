# Common setup for comprehensive evaluation analysis
# This file is sourced at the beginning of each code block in comprehensive_evaluation.org

# Determine the directory of this script
script_dir <- if (exists("ofile") && !is.null(ofile)) {
  dirname(ofile)
} else {
  # Fallback: assume we're in project root or examples directory
  if (file.exists("common_header.R")) {
    "."
  } else if (file.exists("examples/common_header.R")) {
    "examples"
  } else {
    stop("Cannot find common_header.R")
  }
}

# Source common header from the appropriate location
source(file.path(script_dir, "common_header.R"), chdir = TRUE)

#' Analyze a single dataset for impact variance
#'
#' @param db_path Path to the SQLite database file
#' @param measure_column Name of the measurement column (e.g., "baseLog.collisionTimes")
#' @param B Number of bootstrap iterations (default: 1000)
#' @param conf.level Confidence level for CI (default: 0.95)
#' @return A data frame with analysis results
analyze_single_dataset <- function(db_path, measure_column, B = 1000, conf.level = 0.95) {
  # Load and prepare data
  raw_data <- get_data_from_db(db_path)
  prepared_data <- prepare_varience_data(raw_data)

  # Extract measurement columns for base, truthy, and random
  measure_base <- measure_column
  measure_truthy <- sub("baseLog", "truthyLog", measure_column)
  measure_random <- sub("baseLog", "randomLog", measure_column)

  # Check if columns exist
  if (!all(c(measure_base, measure_truthy, measure_random) %in% names(prepared_data))) {
    return(data.frame(
      error = "Measurement columns not found",
      stringsAsFactors = FALSE
    ))
  }

  # Create paired measurement matrices
  H_same <- cbind(
    prepared_data[[measure_base]],
    prepared_data[[measure_truthy]]
  )

  H_rand <- cbind(
    prepared_data[[measure_base]],
    prepared_data[[measure_random]]
  )

  # Remove rows with NA values
  complete_same <- complete.cases(H_same)
  complete_rand <- complete.cases(H_rand)
  complete_both <- complete_same & complete_rand

  H_same <- H_same[complete_both, , drop = FALSE]
  H_rand <- H_rand[complete_both, , drop = FALSE]

  # Run bootstrap impact test
  test_result <- bootstrap_impact_test(
    H_same = H_same,
    H_rand = H_rand,
    conf.level = conf.level,
    B = B,
    alternative = "greater"
  )

  return(test_result)
}

#' Extract parameter index from database filename
#'
#' @param db_path Path to database file (e.g., "data/cog_8_heterogeneous.sqlite3")
#' @return Parameter index as integer
extract_param_index <- function(db_path) {
  basename_file <- basename(db_path)
  # Extract number between "cog_" and "_"
  param_idx <- as.integer(sub("cog_(\\d+)_.*", "\\1", basename_file))
  return(param_idx)
}

#' Extract simulation type from database filename
#'
#' @param db_path Path to database file
#' @return "heterogeneous" or "homogeneous"
extract_sim_type <- function(db_path) {
  basename_file <- basename(db_path)
  if (grepl("heterogeneous", basename_file)) {
    return("heterogeneous")
  } else if (grepl("homogeneous", basename_file)) {
    return("homogeneous")
  } else {
    return("unknown")
  }
}

#' Analyze all datasets for a specific simulation type and measurement
#'
#' @param sim_type "heterogeneous" or "homogeneous"
#' @param measure_column Measurement column name (e.g., "baseLog.collisionTimes")
#' @param data_dir Directory containing SQLite files (default: "data")
#' @param B Number of bootstrap iterations (default: 1000)
#' @param conf.level Confidence level (default: 0.95)
#' @param n_cores Number of CPU cores to use for parallel processing.
#'                Default: NULL (auto-detect, uses all available cores - 1)
#'                Set to 1 to disable parallel processing
#' @return Data frame with results for all parameter indices
analyze_all_parameters <- function(sim_type, measure_column,
                                   data_dir = "data", B = 1000, conf.level = 0.95,
                                   n_cores = NULL) {
  # Find all database files matching the simulation type
  pattern <- paste0("cog_\\d+_", sim_type, "\\.sqlite3")
  db_files <- list.files(data_dir, pattern = pattern, full.names = TRUE)

  # Sort by parameter index
  db_files <- db_files[order(sapply(db_files, extract_param_index))]

  # Determine number of cores to use
  if (is.null(n_cores)) {
    # Auto-detect: use all cores minus 1, minimum 1
    n_cores <- max(1, parallel::detectCores() - 1)
  }

  # Function to process a single database file
  process_db_file <- function(db_file) {
    param_idx <- extract_param_index(db_file)

    # Run analysis
    test_result <- analyze_single_dataset(db_file, measure_column, B, conf.level)

    # Extract relevant statistics
    if ("error" %in% names(test_result)) {
      # Handle error case
      return(data.frame(
        Parameter = param_idx,
        Impact = NA,
        Var_Same = NA,
        Var_Rand = NA,
        Effect_Size = NA,
        P_Value = NA,
        CI_Lower = NA,
        CI_Upper = NA,
        stringsAsFactors = FALSE
      ))
    } else {
      # Extract confidence interval
      ci_lower <- test_result$conf.int[1]
      ci_upper <- test_result$conf.int[2]

      return(data.frame(
        Parameter = param_idx,
        Impact = test_result$impact,
        Var_Same = test_result$var_same,
        Var_Rand = test_result$var_rand,
        Effect_Size = test_result$effect_size,
        P_Value = test_result$p.value,
        CI_Lower = ci_lower,
        CI_Upper = ci_upper,
        stringsAsFactors = FALSE
      ))
    }
  }

  # Run analysis in parallel or sequentially
  if (n_cores > 1 && length(db_files) > 1) {
    # Parallel processing using mclapply (Unix/Linux/Mac)
    # Note: mclapply doesn't work on Windows, falls back to lapply automatically
    results_list <- parallel::mclapply(
      db_files,
      process_db_file,
      mc.cores = n_cores
    )
  } else {
    # Sequential processing
    results_list <- lapply(db_files, process_db_file)
  }

  # Combine all results into a single data frame
  results_df <- do.call(rbind, results_list)

  return(results_df)
}
