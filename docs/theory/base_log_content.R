source("tests/test_sample.R")
# Display sample of base experiment data
cat("Sample Base Experiment Data (First 2 Rows):\n")
cat("===========================================\n")
base_data <- head(test_df, 2) %>% select(matches("base.*"))
print(base_data, width = Inf)

cat("\nBase Experiment Column Names:\n")
base_columns <- names(base_data)
for(i in seq_along(base_columns)) {
  cat(sprintf("  %s\n", base_columns[i]))
}
