source("tests/setup.R")

# Example 2: No Parameter Control (h(x) = constant + noise)
set.seed(123)
n_samples <- 1000
x_range <- c(0, 10)

# Generate parameters (same as before)
base_params <- runif(n_samples, x_range[1], x_range[2])
truthy_params <- base_params
random_params <- runif(n_samples, x_range[1], x_range[2])

# Function that IGNORES the parameter: h(x) = 15 + noise
constant_function <- function(x) rep(15, length(x))  # Constant output!
noise_sd <- 2.0

# Generate measurements (parameter doesn't matter)
base_measurements <- constant_function(base_params) + rnorm(n_samples, 0, noise_sd)
truthy_measurements <- constant_function(truthy_params) + rnorm(n_samples, 0, noise_sd)
random_measurements <- constant_function(random_params) + rnorm(n_samples, 0, noise_sd)

uncontrolled_df <- data.frame(
  base_params = base_params,
  truthy_params = truthy_params,
  random_params = random_params,
  base_h = base_measurements,
  truthy_h = truthy_measurements,
  random_h = random_measurements
)
