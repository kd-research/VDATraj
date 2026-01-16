source("tests/generate_test_data.R")
# Display parameter/time data for first 2 trajectories
# Identify parameter and time-related columns
parameter_columns <- grep("Parameters$", names(test_df), value=TRUE)
time_columns <- grep("Log.*time", names(test_df), value=TRUE)
cols_vector <- c(parameter_columns, time_columns)

cat("Triple Replication Data View (First 2 Trajectories):\n")
cat("====================================================\n")
replica_data <- head(test_df, 2) %>% select(all_of(cols_vector))
print(replica_data, width = Inf)

cat("\nColumn Explanation:\n")
cat("  • baseParameters: Original experiment parameter values\n")
cat("  • truthyParameters: Identical replica parameter values\n")
cat("  • randomParameters: Random replica parameter values\n")
cat("  • *Log.agent_time_enableds: Agent time measurements for each condition\n")
