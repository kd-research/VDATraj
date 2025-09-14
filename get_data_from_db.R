# R equivalent of the get_data_from_db function from the Python notebook
# This function connects to SQLite database, retrieves data with JOIN query,
# and parses JSON strings in columns whose names end with 'Log'

library(DBI)
library(RSQLite)
library(jsonlite)
library(dplyr)
library(purrr)
library(tidyr)

#' Parse a log string by splitting on newlines
#' 
#' Expected format: a header line is ignored, a second line provides keys,
#' and a third line provides corresponding values.
#' Returns a named list mapping keys to values.
#'
#' @param log A character string containing the log data
#' @return A named list with keys mapped to values
parse_log <- function(log) {
  # Split the log string on newlines
  lines <- strsplit(log, "\n")[[1]]
  
  # Check if we have at least 3 lines
  if (length(lines) < 3) {
    stop("Log string must have at least 3 lines")
  }
  
  # Extract header (ignored), keys (second line), and values (third line)
  header <- lines[1]  # ignored
  keys <- strsplit(lines[2], "\\s+")[[1]]
  values <- strsplit(lines[3], "\\s+")[[1]]
  
  # Create named list mapping keys to values
  result <- setNames(as.list(values), keys)
  return(result)
}

#' Parse JSON list of floats to numeric vector
#' 
#' Takes a JSON string representing a list of floats and converts it
#' to a numeric vector in R. Fails fast on parsing errors.
#'
#' @param json_str A JSON string like "[0.1, 0.2, 0.3]"
#' @return A numeric vector
parse_json_floats <- function(json_str) {
  if (is.na(json_str) || is.null(json_str) || json_str == "") {
    stop("JSON string is NA, NULL, or empty")
  }
  
  parsed <- fromJSON(json_str)
  result <- as.numeric(parsed)
  
  if (any(is.na(result))) {
    stop(paste("Failed to convert parsed JSON to numeric:", json_str))
  }
  
  return(result)
}

#' Parse parenthesis-enclosed list of floats to numeric vector
#' 
#' Takes a string with parenthesis-enclosed floats and converts it
#' to a numeric vector in R. Fails fast on parsing errors.
#'
#' @param paren_str A string like "(0.1, 0.2, 0.3)"
#' @return A numeric vector
parse_parenthesis_floats <- function(paren_str) {
  if (is.na(paren_str) || is.null(paren_str) || paren_str == "") {
    stop("Parenthesis string is NA, NULL, or empty")
  }
  
  # Check if string has proper parenthesis format
  if (!grepl("^\\(.*\\)$", paren_str)) {
    stop(paste("String does not have proper parenthesis format:", paren_str))
  }
  
  # Remove parentheses and split by comma
  cleaned <- gsub("^\\(|\\)$", "", paren_str)
  values <- strsplit(cleaned, ",")[[1]]
  # Trim whitespace and convert to numeric
  values <- trimws(values)
  result <- as.numeric(values)
  
  if (any(is.na(result))) {
    stop(paste("Failed to convert parenthesis content to numeric:", paren_str))
  }
  
  return(result)
}

#' Execute SQL query to retrieve raw data from SQLite database
#' 
#' Connects to SQLite database and executes a complex JOIN query
#' to retrieve benchmark and parameter data.
#'
#' @param filename Path to the SQLite database file
#' @return A data frame with raw query results
get_raw_data_from_db <- function(filename) {
  # Check if file exists
  if (!file.exists(filename)) {
    stop(paste("File", filename, "not found."))
  }
  
  # Connect to SQLite database
  conn <- dbConnect(RSQLite::SQLite(), filename)
  
  # Define the SQL query (same as Python version)
  sql_query <- "
    SELECT
        p.parameters as baseParameters,
        p_trth.parameters as truthyParameters,
        p_rndm.parameters as randomParameters,
        b_base.log AS baseLog,
        b_trth.log AS truthyLog,
        b_rndm.log AS randomLog
    FROM parameters p
    JOIN parameter_relations pr1 ON p.id = pr1.from_id
    JOIN parameters p_trth ON p_trth.id = pr1.to_id AND p_trth.label = 'truthy'
    JOIN parameter_relations pr2 ON p.id = pr2.from_id
    JOIN parameters p_rndm ON p_rndm.id = pr2.to_id AND p_rndm.label = 'random'
    JOIN benchmark_log b_base ON p.id = b_base.parameter_object_id
    JOIN benchmark_log b_trth ON p_trth.id = b_trth.parameter_object_id
    JOIN benchmark_log b_rndm ON p_rndm.id = b_rndm.parameter_object_id
    WHERE p.label = 'budget-ground';
  "
  
  # Execute query and get results
  tryCatch({
    df <- dbGetQuery(conn, sql_query)
  }, error = function(e) {
    dbDisconnect(conn)
    stop(paste("Error executing query:", e$message))
  })
  
  # Close database connection
  dbDisconnect(conn)
  
  return(df)
}

#' Parse and process raw data with proper data type conversion
#' 
#' Takes raw data from database and applies parsing logic to extract
#' structured data with correct data types from log columns and parameters.
#'
#' @param raw_df A data frame with raw data from the database
#' @return A data frame with parsed and properly typed data
process_parsed_data <- function(raw_df) {
  # Apply parse_log to any column that ends with "Log"
  log_columns <- grep("Log$", names(raw_df), value = TRUE)
  
  df <- raw_df %>%
    # Parse all log columns and handle errors gracefully
    mutate(across(all_of(log_columns), ~ map(.x, possibly(parse_log, list())))) %>%
    # Flatten nested lists into separate columns with proper naming
    unnest_wider(all_of(log_columns), names_sep = ".")
  
  # Apply JSON parsing to parameter columns (fail fast on errors)
  parameter_columns <- c("baseParameters", "truthyParameters", "randomParameters")
  existing_param_columns <- intersect(parameter_columns, names(df))
  
  if (length(existing_param_columns) > 0) {
    df <- df %>%
      mutate(across(all_of(existing_param_columns), ~ map(.x, parse_json_floats)))
  }
  
  # Apply parenthesis parsing to agent energy, time enabled, collision times, and distance traveled columns (fail fast on errors)
  agent_energy_columns <- grep("Log\\.agent_ple_energys$", names(df), value = TRUE)
  agent_time_columns <- grep("Log\\.agent_time_enableds$", names(df), value = TRUE)
  collision_time_columns <- grep("Log\\.collisionTimes$", names(df), value = TRUE)
  distance_traveled_columns <- grep("Log\\.agent_distance_traveleds$", names(df), value = TRUE)
  parenthesis_columns <- c(agent_energy_columns, agent_time_columns, collision_time_columns, distance_traveled_columns)
  
  if (length(parenthesis_columns) > 0) {
    df <- df %>%
      mutate(across(all_of(parenthesis_columns), ~ map(.x, parse_parenthesis_floats)))
  }
  
  return(df)
}

#' Connect to SQLite database and retrieve processed data
#' 
#' Main function that combines SQL data retrieval with data parsing
#' and type conversion. This is the primary interface for users.
#'
#' @param filename Path to the SQLite database file
#' @return A data frame with processed and properly typed data
get_data_from_db <- function(filename) {
  # Get raw data from database
  raw_df <- get_raw_data_from_db(filename)
  
  # Process and parse the data
  processed_df <- process_parsed_data(raw_df)
  
  return(processed_df)
}

# Example usage:
# df <- get_data_from_db("path/to/your/database.sqlite3")
# print(head(df))
