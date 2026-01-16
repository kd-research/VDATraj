source("tests/generate_test_data.R")
# Calculate and interpret impact variance
# Calculate all variance components
base_variance <- var(test_df$baseLog.agent_time_enableds)
same_param_diff <- test_df$baseLog.agent_time_enableds - test_df$truthyLog.agent_time_enableds
replica_variance <- var(same_param_diff)
random_param_diff <- test_df$baseLog.agent_time_enableds - test_df$randomLog.agent_time_enableds
random_variance <- var(random_param_diff)

# Impact variance calculation
impact_variance <- random_variance - replica_variance

cat("Impact Variance Calculation Summary\n")
cat("===================================\n")
cat(sprintf("Base measurement variance:           %12.6f\n", base_variance))
cat(sprintf("Same parameter variance (noise):     %12.6f\n", replica_variance))
cat(sprintf("Random parameter variance (noise+signal): %12.6f\n", random_variance))
cat(sprintf("Impact variance (signal only):       %12.6f\n", impact_variance))

cat("\nVariance Decomposition:\n")
cat(sprintf("  • Pure measurement noise component: %12.6f (%.1f%%)\n", 
    replica_variance, 100 * replica_variance / random_variance))
cat(sprintf("  • Parameter influence component:     %12.6f (%.1f%%)\n", 
    impact_variance, 100 * impact_variance / random_variance))

cat("\nConclusion:\n")
if(impact_variance > 0) {
  cat(sprintf("  ✓ Positive impact variance (%.2f) indicates meaningful parameter control\n", impact_variance))
  cat(sprintf("  ✓ Parameters explain %.1f%% of the additional variance beyond noise\n", 
      100 * impact_variance / random_variance))
  cat("  ✓ Input parameters have demonstrable influence on trajectory outcomes\n")
} else {
  cat("  ✗ No evidence of parameter influence (impact variance ≤ 0)\n")
}
