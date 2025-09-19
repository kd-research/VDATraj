source("prelude/prelude.R")

# Generate synthetic data with sinusoidal mapping function h(x) = sin(x) + noise
# This creates a dataset where the output has a clear sinusoidal relationship with input

set.seed(42)  # For reproducible results
n_samples <- 1000

# Generate base parameters from uniform distribution [0, 2π]
base_params <- runif(n_samples, 0, 2*pi)

# For truthy replicates, use exactly the same parameters
truthy_params <- base_params

# For random replicates, generate new random parameters from same distribution
random_params <- runif(n_samples, 0, 2*pi)

# Define noise level
noise_sd <- 0.3

# Generate measurements using h(x) = sin(x) + noise
# Base measurements
base_time_enabled <- sin(base_params) + rnorm(n_samples, 0, noise_sd)
base_collision_times <- sin(base_params) * 0.8 + rnorm(n_samples, 0, noise_sd)
base_distance_traveled <- sin(base_params) * 1.2 + rnorm(n_samples, 0, noise_sd)
base_ple_energy <- sin(base_params) * 2.0 + rnorm(n_samples, 0, noise_sd)

# Truthy measurements (same parameters, different noise realization)
truthy_time_enabled <- sin(truthy_params) + rnorm(n_samples, 0, noise_sd)
truthy_collision_times <- sin(truthy_params) * 0.8 + rnorm(n_samples, 0, noise_sd)
truthy_distance_traveled <- sin(truthy_params) * 1.2 + rnorm(n_samples, 0, noise_sd)
truthy_ple_energy <- sin(truthy_params) * 2.0 + rnorm(n_samples, 0, noise_sd)

# Random measurements (different parameters)
random_time_enabled <- sin(random_params) + rnorm(n_samples, 0, noise_sd)
random_collision_times <- sin(random_params) * 0.8 + rnorm(n_samples, 0, noise_sd)
random_distance_traveled <- sin(random_params) * 1.2 + rnorm(n_samples, 0, noise_sd)
random_ple_energy <- sin(random_params) * 2.0 + rnorm(n_samples, 0, noise_sd)

# Create the test dataframe following the same structure as the original
test_sin_df <- data.frame(
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