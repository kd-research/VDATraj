source("tests/test_sample.R")
# Calculate total variance of base experiment measurements
base_variance <- var(test_df$baseLog.agent_time_enableds)

cat("Base Experiment Measurement Variance Analysis\n")
cat("==============================================\n")
cat(sprintf("Total variance of agent_time_enabled measurements: %.6f\n", base_variance))
cat("\nThis represents the total variability in the primary outcome measurement\n")
cat("across all trajectories in the base experiment.\n")
