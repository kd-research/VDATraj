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

#' Cached analysis of all parameters with automatic result storage
#'
#' @param sim_type "heterogeneous" or "homogeneous"
#' @param measure_column Measurement column name (e.g., "baseLog.collisionTimes")
#' @param data_dir Directory containing SQLite files (default: "data")
#' @param B Number of bootstrap iterations (default: 1000)
#' @param conf.level Confidence level (default: 0.95)
#' @param n_cores Number of CPU cores to use for parallel processing.
#'                Default: NULL (auto-detect, uses all available cores - 1)
#' @param cache_dir Directory to store cached results (default: "cache")
#' @param force_refresh If TRUE, ignore cached results and recompute (default: FALSE)
#' @return Data frame with results for all parameter indices
analyze_all_parameters_cached <- function(sim_type, measure_column,
                                          data_dir = "data", B = 1000, conf.level = 0.95,
                                          n_cores = NULL,
                                          cache_dir = "cache",
                                          force_refresh = FALSE) {
  # Ensure cache directory exists
  if (!dir.exists(cache_dir)) {
    dir.create(cache_dir, recursive = TRUE)
  }

  # Create a unique cache key based on parameters
  cache_key <- digest::digest(list(
    sim_type = sim_type,
    measure_column = measure_column,
    data_dir = data_dir,
    B = B,
    conf.level = conf.level,
    # Also include file modification times to detect data changes
    file_mtimes = file.info(list.files(data_dir, 
                                       pattern = paste0("cog_\\d+_", sim_type, "\\.sqlite3"),
                                       full.names = TRUE))$mtime
  ))

  # Construct cache file path
  cache_file <- file.path(
    cache_dir,
    paste0("analysis_", sim_type, "_", 
           gsub("[^a-zA-Z0-9]", "_", measure_column), "_",
           cache_key, ".rds")
  )

  # Check if cached result exists and is valid
  if (!force_refresh && file.exists(cache_file)) {
    message("Loading cached results from: ", cache_file)
    results <- readRDS(cache_file)
    
    # Validate cached result structure
    if (is.data.frame(results) && nrow(results) > 0) {
      return(results)
    } else {
      message("Cached result is invalid, recomputing...")
    }
  }

  # Compute results if no valid cache exists
  message("Computing analysis results (this may take a while)...")
  results <- analyze_all_parameters(
    sim_type = sim_type,
    measure_column = measure_column,
    data_dir = data_dir,
    B = B,
    conf.level = conf.level,
    n_cores = n_cores
  )

  # Save results to cache
  message("Saving results to cache: ", cache_file)
  saveRDS(results, cache_file)

  # Clean up old cache files for the same parameters (different hashes)
  old_pattern <- paste0("analysis_", sim_type, "_", 
                        gsub("[^a-zA-Z0-9]", "_", measure_column), "_.*\\.rds")
  old_files <- list.files(cache_dir, pattern = old_pattern, full.names = TRUE)
  old_files <- old_files[old_files != cache_file]
  
  if (length(old_files) > 0) {
    message("Cleaning up ", length(old_files), " old cache file(s)")
    unlink(old_files)
  }

  return(results)
}

#' Clear all cached analysis results
#'
#' @param cache_dir Directory containing cached results (default: "cache")
#' @param pattern Optional pattern to match specific cache files (default: NULL, clears all)
#' @return Number of files deleted
clear_analysis_cache <- function(cache_dir = "cache", pattern = NULL) {
  if (!dir.exists(cache_dir)) {
    message("Cache directory does not exist: ", cache_dir)
    return(0)
  }

  if (is.null(pattern)) {
    pattern <- "analysis_.*\\.rds"
  }

  cache_files <- list.files(cache_dir, pattern = pattern, full.names = TRUE)
  
  if (length(cache_files) == 0) {
    message("No cache files found to delete")
    return(0)
  }

  message("Deleting ", length(cache_files), " cache file(s)")
  unlink(cache_files)
  
  return(length(cache_files))
}
