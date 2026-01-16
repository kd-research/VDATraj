library(here)
source(here("examples", "03_sinusoidal_example.R"))

# Data loaded from prelude/sinusoidal_example.R
cat("Experiment 3: Cosine Parameter Dependence\n")
cat("=============================================\n")
cat("Sample size:", nrow(sinusoidal_df), "\n")
cat("Parameter range: [", round(min(sinusoidal_df$base_params), 2), ",", round(max(sinusoidal_df$base_params), 2), "] radians\n")
cat("True model: h(x) = cos(x) + N(0, 0.64)\n")
cat("Key insight: Even function → Zero correlation but strong parameter dependence\n")
cat("Data structure:\n")
str(sinusoidal_df)
