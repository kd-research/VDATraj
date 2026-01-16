source("tests/test_sample.R")
# Display variable names from the loaded dataset
cat("Dataset Variables (Sorted Alphabetically):\n")
cat("==========================================\n")
variable_names <- names(test_df) %>% sort()
for(i in seq_along(variable_names)) {
  cat(sprintf("%2d. %s\n", i, variable_names[i]))
}
cat(sprintf("\nTotal number of variables: %d\n", length(variable_names)))
