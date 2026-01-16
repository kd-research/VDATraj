source("tests/generate_test_data.R")
# Calculate variance of differences between random parameter replications
# Calculate difference between base and random parameter measurements
differences <- test_df$baseLog.agent_time_enableds - test_df$randomLog.agent_time_enableds
random_variance <- var(differences)

cat("Random Parameter Variance Analysis\n")
cat("===================================\n")
cat("Comparing measurements between different parameter values:\n")
cat(sprintf("  • Base experiment mean: %.6f\n", mean(test_df$baseLog.agent_time_enableds)))
cat(sprintf("  • Random replica mean: %.6f\n", mean(test_df$randomLog.agent_time_enableds)))
cat(sprintf("  • Mean difference: %.6f\n", mean(differences)))
cat(sprintf("  • Variance of differences: %.6f\n", random_variance))

cat("\nInterpretation:\n")
cat("  • This variance captures both measurement noise AND parameter effects\n")
cat("  • According to theory: Var(Y_random) = 2σ² + 2Var(μ_X)\n")
cat("  • Higher than same-parameter variance indicates parameter influence\n")
