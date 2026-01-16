library(here)
source(here("examples", "03_sinusoidal_example.R"))

# Apply variance decomposition protocol
base_variance <- var(sinusoidal_df$base_h)
cat("Total measurement variance:", base_variance, "\n")

# Same parameter variance (measurement noise only)
same_param_differences <- sinusoidal_df$base_h - sinusoidal_df$truthy_h
same_param_variance <- var(same_param_differences)
cat("Same parameter variance (2σ²):", same_param_variance, "\n")

# Random parameter variance (noise + parameter effect)
random_param_differences <- sinusoidal_df$base_h - sinusoidal_df$random_h
random_param_variance <- var(random_param_differences)
cat("Random parameter variance:", random_param_variance, "\n")

# Impact variance calculation
observed_impact_variance <- random_param_variance - same_param_variance
cat("Observed impact variance:", observed_impact_variance, "\n")

# Direct correlation analysis (should be near zero!)
correlation <- cor(sinusoidal_df$base_params, sinusoidal_df$base_h)
cat("Direct linear correlation:", round(correlation, 4), "\n")

cat("\n=== METHOD COMPARISON ===\n")
cat("Traditional Correlation Analysis:\n")
if (abs(correlation) < 0.1) {
  cat("✗ FAILURE: Correlation ≈ 0, suggests NO parameter influence\n")
} else {
  cat("✓ SUCCESS: Correlation detects parameter influence\n")
}

cat("\nVariance Decomposition Method:\n")
if (observed_impact_variance > same_param_variance * 0.1) {
  cat("✓ SUCCESS: Impact variance detects STRONG parameter influence\n")
  cat("  Effect size:", round(observed_impact_variance / same_param_variance, 2), "x noise level\n")
} else {
  cat("✗ FAILURE: Impact variance suggests weak parameter influence\n")
}

cat("\n=== KEY INSIGHT ===\n")
cat("This demonstrates why variance decomposition is superior to correlation\n")
cat("for detecting non-linear parameter relationships!\n")
