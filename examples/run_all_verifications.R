source("tests/setup.R")

# Load all verification examples
source("examples/01_controlled_example.R")
source("examples/02_uncontrolled_example.R") 
source("examples/03_sinusoidal_example.R")
source("examples/04_trajectory_example.R")

# Create a summary function to analyze any dataset with the variance decomposition method
analyze_variance_decomposition <- function(df, base_param_col, truthy_param_col, random_param_col, 
                                         base_measure_col, truthy_measure_col, random_measure_col) {
  
  # Extract the relevant columns
  base_params <- df[[base_param_col]]
  base_measure <- df[[base_measure_col]]
  truthy_measure <- df[[truthy_measure_col]]
  random_measure <- df[[random_measure_col]]
  
  # Calculate variances
  base_variance <- var(base_measure)
  same_param_diff <- base_measure - truthy_measure
  same_param_variance <- var(same_param_diff)
  random_param_diff <- base_measure - random_measure
  random_param_variance <- var(random_param_diff)
  impact_variance <- random_param_variance - same_param_variance
  
  # Return results
  results <- list(
    base_variance = base_variance,
    same_param_variance = same_param_variance,
    random_param_variance = random_param_variance,
    impact_variance = impact_variance,
    correlation = cor(base_params, base_measure)
  )
  
  return(results)
}

# Pre-compute results for all examples
controlled_results <- analyze_variance_decomposition(
  controlled_df, "base_params", "truthy_params", "random_params",
  "base_h", "truthy_h", "random_h"
)

uncontrolled_results <- analyze_variance_decomposition(
  uncontrolled_df, "base_params", "truthy_params", "random_params", 
  "base_h", "truthy_h", "random_h"
)

sinusoidal_results <- analyze_variance_decomposition(
  sinusoidal_df, "base_params", "truthy_params", "random_params",
  "base_h", "truthy_h", "random_h"
)

trajectory_results <- analyze_variance_decomposition(
  trajectory_df, "base_delay_time", "truthy_delay_time", "random_delay_time",
  "base_collision_times", "truthy_collision_times", "random_collision_times"
)
