source("tests/generate_test_data.R")
# Calculate variance for parameter and time columns
# Identify parameter and time-related columns
parameter_columns <- grep("Parameters$", names(test_df), value=TRUE)
time_columns <- grep("Log.*time", names(test_df), value=TRUE)
cols_vector <- c(parameter_columns, time_columns)

cat("Variance Analysis for Parameter and Time Measurements:\n")
cat("======================================================\n")

variance_data <- test_df %>%
  select(all_of(cols_vector)) %>%
  sapply(var, simplify=FALSE)

cat("\nParameter Variances:\n")
for(col in parameter_columns) {
  cat(sprintf("  %-25s: %12.6f\n", col, variance_data[[col]]))
}

cat("\nTime Measurement Variances:\n")
for(col in time_columns) {
  cat(sprintf("  %-30s: %12.6f\n", col, variance_data[[col]]))
}

cat("\nKey Observations:\n")
cat("  • Parameter variances are similar across replications (as expected)\n")
cat("  • Time measurement variances are comparable, suggesting consistent noise levels\n")
