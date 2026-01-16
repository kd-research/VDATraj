# Apply variance decomposition protocol
library(here)
source(here("examples", "01_controlled_example.R"))
base_variance <- var(controlled_df$base_h)
cat("Total measurement variance:", base_variance, "\n")

# Same parameter variance (measurement noise only)
same_param_differences <- controlled_df$base_h - controlled_df$truthy_h
same_param_variance <- var(same_param_differences)
cat("Same parameter variance (2σ²):", same_param_variance, "\n")

# Random parameter variance (noise + parameter effect)
random_param_differences <- controlled_df$base_h - controlled_df$random_h
random_param_variance <- var(random_param_differences)
cat("Random parameter variance:", random_param_variance, "\n")

# Impact variance calculation
observed_impact_variance <- random_param_variance - same_param_variance
cat("Observed impact variance:", observed_impact_variance, "\n")

# Theoretical validation
theoretical_noise_component <- 2 * 1^2  # noise_std = 1
theoretical_signal_component <- 2 * 2^2 * var(controlled_df$base_params)  # slope = 2
expected_impact_variance <- theoretical_signal_component

cat("\n--- Theoretical Validation ---\n")
cat("Expected noise component (2σ²):", theoretical_noise_component, "\n")
cat("Expected signal component (2β²Var(X)):", theoretical_signal_component, "\n")
cat("Expected impact variance:", expected_impact_variance, "\n")
cat("Observed impact variance:", observed_impact_variance, "\n")
cat("Relative error:", abs(observed_impact_variance - expected_impact_variance) / expected_impact_variance * 100, "%\n")

# Validation assessment
if (abs(observed_impact_variance - expected_impact_variance) / expected_impact_variance < 0.1) {
  cat("✓ VALIDATION SUCCESSFUL: Observed values match theoretical predictions\n")
} else {
  cat("⚠ VALIDATION WARNING: Larger deviation from theoretical predictions\n")
}
