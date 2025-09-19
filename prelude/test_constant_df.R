source("prelude/prelude.R")

# Generate synthetic data with constant mapping function h(x) = C + noise
# This creates a dataset where the output is independent of input (constant function)

set.seed(123)  # For reproducible results
n_samples <- 1000

# Generate base parameters from uniform distribution [0, 1]
base_params <- runif(n_samples, 0, 1)

# For truthy replicates, use exactly the same parameters
truthy_params <- base_params

# For random replicates, generate new random parameters from same distribution
random_params <- runif(n_samples, 0, 1)

# Define constants and noise level
constant_time <- 25.0      # Constant value for time measurements
constant_collision <- 30.0 # Constant value for collision measurements
constant_distance <- 20.0  # Constant value for distance measurements
constant_energy <- 75.0    # Constant value for energy measurements
noise_sd <- 2.0            # Higher noise to show pure noise variance

# Generate measurements using h(x) = C + noise (independent of x)
# Base measurements
base_time_enabled <- rep(constant_time, n_samples) + rnorm(n_samples, 0, noise_sd)
base_collision_times <- rep(constant_collision, n_samples) + rnorm(n_samples, 0, noise_sd)
base_distance_traveled <- rep(constant_distance, n_samples) + rnorm(n_samples, 0, noise_sd)
base_ple_energy <- rep(constant_energy, n_samples) + rnorm(n_samples, 0, noise_sd)

# Truthy measurements (same parameters, different noise realization)
truthy_time_enabled <- rep(constant_time, n_samples) + rnorm(n_samples, 0, noise_sd)
truthy_collision_times <- rep(constant_collision, n_samples) + rnorm(n_samples, 0, noise_sd)
truthy_distance_traveled <- rep(constant_distance, n_samples) + rnorm(n_samples, 0, noise_sd)
truthy_ple_energy <- rep(constant_energy, n_samples) + rnorm(n_samples, 0, noise_sd)

# Random measurements (different parameters, but output still constant + noise)
random_time_enabled <- rep(constant_time, n_samples) + rnorm(n_samples, 0, noise_sd)
random_collision_times <- rep(constant_collision, n_samples) + rnorm(n_samples, 0, noise_sd)
random_distance_traveled <- rep(constant_distance, n_samples) + rnorm(n_samples, 0, noise_sd)
random_ple_energy <- rep(constant_energy, n_samples) + rnorm(n_samples, 0, noise_sd)

# Create the test dataframe following the same structure as the original
test_constant_df <- data.frame(
  baseParameters = base_params,
  truthyParameters = truthy_params,
  randomParameters = random_params,
  baseLog.agent_time_enableds = base_time_enabled,
  baseLog.collisionTimes = base_collision_times,
  baseLog.agent_distance_traveleds = base_distance_traveled,
  baseLog.agent_ple_energys = base_ple_energy,
  truthyLog.agent_time_enableds = truthy_time_enabled,
  truthyLog.collisionTimes = truthy_collision_times,
  truthyLog.agent_distance_traveleds = truthy_distance_traveled,
  truthyLog.agent_ple_energys = truthy_ple_energy,
  randomLog.agent_time_enableds = random_time_enabled,
  randomLog.collisionTimes = random_collision_times,
  randomLog.agent_distance_traveleds = random_distance_traveled,
  randomLog.agent_ple_energys = random_ple_energy
)