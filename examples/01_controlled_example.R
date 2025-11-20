# Load here package for path-independent sourcing
if (!require("here", quietly = TRUE)) install.packages("here")
source(here::here("examples", "common_header.R"))

# Example 1: Clear Parameter Control (h(x) = 2x + 5 + noise)
set.seed(42)
n_samples <- 1000
x_range <- c(0, 10)

# Generate base parameters
base_params <- runif(n_samples, x_range[1], x_range[2])
truthy_params <- base_params # Same parameters for replica
random_params <- runif(n_samples, x_range[1], x_range[2]) # Different parameters

# True function: h(x) = 2x + 5 + noise
true_function <- function(x) 2 * x + 5
noise_sd <- 1.0

# Generate measurements
base_measurements <- true_function(base_params) + rnorm(n_samples, 0, noise_sd)
truthy_measurements <- true_function(truthy_params) + rnorm(n_samples, 0, noise_sd)
random_measurements <- true_function(random_params) + rnorm(n_samples, 0, noise_sd)

controlled_df <- data.frame(
  base_params = base_params,
  truthy_params = truthy_params,
  random_params = random_params,
  base_h = base_measurements,
  truthy_h = truthy_measurements,
  random_h = random_measurements
)
