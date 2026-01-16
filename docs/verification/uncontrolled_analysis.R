library(here)
source(here("examples", "02_uncontrolled_example.R"))

# Same analysis as before
base_variance <- var(uncontrolled_df$base_h)
cat("Base variance Var(H):", base_variance, "\n")

same_param_diff <- uncontrolled_df$base_h - uncontrolled_df$truthy_h
same_param_variance <- var(same_param_diff)
cat("Same parameter variance Var(H-H'|X=x):", same_param_variance, "\n")

random_param_diff <- uncontrolled_df$base_h - uncontrolled_df$random_h
random_param_variance <- var(random_param_diff)
cat("Random parameter variance Var(H(X)-H'(X')):", random_param_variance, "\n")

impact_variance <- random_param_variance - same_param_variance
cat("Impact variance (difference):", impact_variance, "\n")

# Theoretical predictions for NO control
theoretical_noise_variance <- 2 * noise_sd^2
theoretical_signal_variance <- 0  # No dependence on X!
theoretical_impact <- 0

cat("\n--- Theoretical vs Observed ---\n")
cat("Expected noise component (2σ²):", theoretical_noise_variance, "\n")
cat("Expected signal component (0):", theoretical_signal_variance, "\n")
cat("Expected impact variance (0):", theoretical_impact, "\n")
cat("Observed impact variance:", impact_variance, "\n")

# The key test: impact variance should be near zero!
if (abs(impact_variance) < 1.0) {
  cat("✓ SUCCESS: Method correctly identifies NO parameter control\n")
} else {
  cat("✗ FAILURE: Method incorrectly suggests parameter control\n")
}
