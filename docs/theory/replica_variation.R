source("tests/generate_test_data.R")
# Calculate variance of differences between identical parameter replications
# Calculate difference between base and truthy (identical parameter) measurements
differences <- test_df$baseLog.agent_time_enableds - test_df$truthyLog.agent_time_enableds
replica_variance <- var(differences)

cat("Same Parameter Replica Variance Analysis\n")
cat("========================================\n")
cat("Comparing measurements from identical parameter replications:\n")
cat(sprintf("  • Base experiment mean: %.6f\n", mean(test_df$baseLog.agent_time_enableds)))
cat(sprintf("  • Truthy replica mean: %.6f\n", mean(test_df$truthyLog.agent_time_enableds)))
cat(sprintf("  • Mean difference: %.6f\n", mean(differences)))
cat(sprintf("  • Variance of differences: %.6f\n", replica_variance))

cat("\nInterpretation:\n")
cat("  • This variance captures pure measurement noise (σ²)\n")
cat("  • Represents variability when parameters are held constant\n")
cat("  • According to theory: Var(Y_same) = 2σ²\n")
