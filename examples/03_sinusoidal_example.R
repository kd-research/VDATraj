# Load here package for path-independent sourcing
if (!require("here", quietly = TRUE)) install.packages("here")
source(here::here("examples", "common_header.R"))

# Example 4: Cosine relationship - zero correlation but strong parameter dependence
set.seed(456)
n_samples <- 1000

# Generate parameters over multiple periods to ensure near-zero correlation
x_range <- c(-2 * pi, 2 * pi) # Symmetric around zero for better balance
base_params <- runif(n_samples, x_range[1], x_range[2])
truthy_params <- base_params # Same parameters for replica
random_params <- runif(n_samples, x_range[1], x_range[2]) # Different parameters

# Cosine function: h(x) = cos(x) + noise
# This has ZERO linear correlation (even function, symmetric) but strong parameter dependence
sinusoidal_function <- function(x) cos(x)
noise_sd <- 0.8

# Generate measurements
base_measurements <- sinusoidal_function(base_params) + rnorm(n_samples, 0, noise_sd)
truthy_measurements <- sinusoidal_function(truthy_params) + rnorm(n_samples, 0, noise_sd)
random_measurements <- sinusoidal_function(random_params) + rnorm(n_samples, 0, noise_sd)

sinusoidal_df <- data.frame(
  base_params = base_params,
  truthy_params = truthy_params,
  random_params = random_params,
  base_h = base_measurements,
  truthy_h = truthy_measurements,
  random_h = random_measurements
)

cat("Cosine example data generated\n")
cat("Function: h(x) = cos(x) + N(0,", noise_sd^2, ")\n")
cat("Parameter range: [", round(x_range[1], 2), ",", round(x_range[2], 2), "] (", round(x_range[2] / pi, 1), "π)\n")
cat("Expected: Zero correlation but strong parameter dependence!\n")
