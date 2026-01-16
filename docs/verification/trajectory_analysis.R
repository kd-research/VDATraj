library(here)
source(here("examples", "04_trajectory_example.R"))

# Apply variance decomposition method to real simulation data
base_variance <- var(trajectory_df$base_collision_times)
cat("Base variance Var(collision_times):", round(base_variance, 3), "\n")

# Same parameter variance (simulation noise only)
same_param_diff <- trajectory_df$base_collision_times - trajectory_df$truthy_collision_times
same_param_variance <- var(same_param_diff)
cat("Same parameter variance:", round(same_param_variance, 3), "\n")

# Random parameter variance (simulation noise + parameter effect)
random_param_diff <- trajectory_df$base_collision_times - trajectory_df$random_collision_times
random_param_variance <- var(random_param_diff)
cat("Random parameter variance:", round(random_param_variance, 3), "\n")

# Impact variance - key metric for parameter influence
impact_variance <- random_param_variance - same_param_variance
cat("Impact variance (delay time effect):", round(impact_variance, 3), "\n")

# Direct correlation analysis
correlation <- cor(trajectory_df$base_delay_time, trajectory_df$base_collision_times)
cat("Direct correlation (delay_time vs collision_times):", round(correlation, 4), "\n")

# Statistical significance assessment
cat("\n--- Analysis Results ---\n")
if (abs(impact_variance) > same_param_variance * 0.1) {
  cat("✓ SIGNIFICANT: Visual perception delay time influences collision times\n")
  cat("  Impact variance indicates meaningful parameter control\n")
  cat("  Effect size: ", round(impact_variance / same_param_variance, 2), "x simulation noise\n")
} else {
  cat("○ MINIMAL: Limited evidence of parameter influence\n")  
  cat("  Impact variance similar to simulation noise level\n")
}

# Descriptive statistics
cat("\nDescriptive Statistics:\n")
cat("Delay time statistics: Mean =", round(mean(trajectory_df$base_delay_time), 3), 
    ", SD =", round(sd(trajectory_df$base_delay_time), 3), "\n")
cat("Collision times statistics: Mean =", round(mean(trajectory_df$base_collision_times), 1), 
    ", SD =", round(sd(trajectory_df$base_collision_times), 1), "\n")
