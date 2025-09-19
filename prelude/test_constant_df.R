source("prelude/prelude.R")

# Generate synthetic data with constant mapping function h(x) = C + noise
# Simple 3-column structure: x (parameters) and y (outputs) for variance analysis

set.seed(123)  # For reproducible results
n_samples <- 1000

# Generate base parameters from uniform distribution [0, 1]
base_x <- runif(n_samples, 0, 1)

# For truthy replicates, use exactly the same parameters
truthy_x <- base_x

# For random replicates, generate new random parameters from same distribution
random_x <- runif(n_samples, 0, 1)

# Define constant and noise level
constant_value <- 5.0  # Constant output value
noise_sd <- 0.5       # Noise level

# Generate outputs using h(x) = C + noise (independent of x)
base_y <- rep(constant_value, n_samples) + rnorm(n_samples, 0, noise_sd)
truthy_y <- rep(constant_value, n_samples) + rnorm(n_samples, 0, noise_sd)  # Same x, different noise
random_y <- rep(constant_value, n_samples) + rnorm(n_samples, 0, noise_sd)  # Different x, same output

# Create simple dataframe with generic x,y structure
test_constant_df <- data.frame(
  base_x = base_x,
  base_y = base_y,
  truthy_x = truthy_x,
  truthy_y = truthy_y,
  random_x = random_x,
  random_y = random_y
)