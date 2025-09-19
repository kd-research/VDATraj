source("prelude/prelude.R")

# Generate synthetic data with sinusoidal mapping function h(x) = sin(x) + noise
# Simple 3-column structure: x (parameters) and y (outputs) for variance analysis

set.seed(42)  # For reproducible results
n_samples <- 1000

# Generate base parameters from uniform distribution [0, 2π]
base_x <- runif(n_samples, 0, 2*pi)

# For truthy replicates, use exactly the same parameters
truthy_x <- base_x

# For random replicates, generate new random parameters from same distribution
random_x <- runif(n_samples, 0, 2*pi)

# Define noise level
noise_sd <- 0.3

# Generate outputs using h(x) = sin(x) + noise
base_y <- sin(base_x) + rnorm(n_samples, 0, noise_sd)
truthy_y <- sin(truthy_x) + rnorm(n_samples, 0, noise_sd)  # Same x, different noise
random_y <- sin(random_x) + rnorm(n_samples, 0, noise_sd)  # Different x

# Create simple dataframe with generic x,y structure
test_sin_df <- data.frame(
  base_x = base_x,
  base_y = base_y,
  truthy_x = truthy_x,
  truthy_y = truthy_y,
  random_x = random_x,
  random_y = random_y
)