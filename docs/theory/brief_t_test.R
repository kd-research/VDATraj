source("tests/generate_test_data.R")
# Perform t-test comparing base vs random parameter measurements
cat("Statistical Comparison: Base vs Random Parameter Measurements\n")
cat("=============================================================\n")
cat("Comparing agent_time_enabled measurements between:\n")
cat("  • Base experiment (original parameters)\n")
cat("  • Random experiment (random parameters)\n\n")

t_test_result <- t.test(test_df$baseLog.agent_time_enableds, test_df$randomLog.agent_time_enableds)
print(t_test_result)

cat("\nInterpretation:\n")
cat(sprintf("  • Mean difference: %.4f\n", diff(t_test_result$estimate)))
cat(sprintf("  • P-value: %.4f\n", t_test_result$p.value))
if(t_test_result$p.value > 0.05) {
  cat("  • No significant difference detected by t-test\n")
  cat("  • This motivates the need for variance decomposition analysis\n")
} else {
  cat("  • Significant difference detected\n")
}
