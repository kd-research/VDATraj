#' Prepare variance data by unnesting nested columns from database
#'
#' This function takes a data frame with nested list columns (from JSON/log parsing)
#' and expands them into separate rows for variance analysis. It handles both
#' parameter columns (containing JSON arrays) and measure columns (containing
#' parsed log data) from multi-agent simulation results.
#'
#' @param df A data frame containing nested columns from get_data_from_db()
#'           Expected to have parameter columns with JSON arrays and
#'           log-derived measure columns with parsed numeric vectors
#' @return A data frame with all nested columns unnested into separate rows
#' @examples
#' # Assuming df comes from get_data_from_db()
#' expanded_data <- prepare_varience_data(df)
prepare_varience_data <- function(df) {
  # Define parameter columns that contain JSON arrays to be unnested
  # These come from the database query and contain experiment parameters
  parameter_columns <- c("baseParameters", "truthyParameters", "randomParameters")
  measure_columns_prefix <- c("baseLog", "truthyLog", "randomLog")
  measure_columns <- c(
    "agent_time_enableds", "collisionTimes", "agent_distance_traveleds",
    "agent_ple_energys"
  )

  # Create all combinations of prefix and measure columns
  combined_measure_columns <- outer(measure_columns_prefix, measure_columns,
    FUN = paste, sep = "."
  )

  # Convert the resulting matrix to a flat vector of column names
  # This gives us all 12 combinations (3 prefixes × 4 measures)
  combined_measure_columns <- as.vector(combined_measure_columns)

  # Combine parameter columns and measure columns into one list
  # These are all the columns that contain nested data (lists/vectors) that need unnesting
  columns_to_expand <- c(parameter_columns, combined_measure_columns)

  # Select only the columns we want to keep and unnest them
  # Use any_of() to select only columns that exist in the dataframe
  # This removes any other columns from the original dataframe and expands
  # each list element into separate rows, creating a long-format dataset
  # suitable for variance analysis and statistical modeling
  existing_columns <- intersect(columns_to_expand, names(df))

  expanded_df <- df %>%
    select(all_of(existing_columns)) %>%
    unnest(cols = all_of(existing_columns))

  return(expanded_df)
}
