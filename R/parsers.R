# Parse utility functions for data processing
# This file contains utility functions for parsing various data formats

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
  header <- lines[1] # ignored
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
