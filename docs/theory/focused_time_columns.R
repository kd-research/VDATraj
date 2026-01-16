source("tests/generate_test_data.R")
# Identify parameter and time-related columns
parameter_columns <- grep("Parameters$", names(test_df), value=TRUE)
time_columns <- grep("Log.*time", names(test_df), value=TRUE)
focused_columns <- c(parameter_columns, time_columns)

cat("Parameter and Time-Related Columns:\n")
cat("====================================\n")
cat("\nParameter Columns:\n")
for(col in parameter_columns) {
  cat(sprintf("  • %s\n", col))
}
cat("\nTime-Related Log Columns:\n")
for(col in time_columns) {
  cat(sprintf("  • %s\n", col))
}
cat(sprintf("\nTotal focused columns: %d\n", length(focused_columns)))
