# Source utility functions for parsing
source("parse_utils.R")


#' Execute SQL query to retrieve raw data from SQLite database
#' 
#' Connects to SQLite database and executes a complex JOIN query
#' to retrieve benchmark and parameter data.
#'
#' @param filename Path to the SQLite database file
#' @param limit Optional integer to limit the number of rows returned (default: NULL for no limit)
#' @return A data frame with raw query results
get_raw_data_from_db <- function(filename, limit = NULL) {
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
    WHERE p.label = 'budget-ground'
  "
  
  # Add LIMIT clause if limit parameter is provided
  if (!is.null(limit) && is.numeric(limit) && limit > 0) {
    sql_query <- paste0(sql_query, " LIMIT ", as.integer(limit))
  }
  
  # Add semicolon at the end
  sql_query <- paste0(sql_query, ";")
  
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
#' @param limit Optional integer to limit the number of rows returned (default: NULL for no limit)
#' @return A data frame with processed and properly typed data
get_data_from_db <- function(filename, limit = NULL) {
  # Get raw data from database
  raw_df <- get_raw_data_from_db(filename, limit)
  
  # Process and parse the data
  processed_df <- process_parsed_data(raw_df)
  
  return(processed_df)
}

# Example usage:
# df <- get_data_from_db("path/to/your/database.sqlite3")
# df_limited <- get_data_from_db("path/to/your/database.sqlite3", limit = 100)
# print(head(df))
