source("tests/setup.R")

# Example 3: Real trajectory data analysis using visual perception delay time and collision times
cat("Loading real trajectory simulation data...\n")
real_data <- get_data_from_db("data/cog_8_heterogeneous.sqlite3")
real_data <- prepare_varience_data(real_data)

# Extract relevant columns for trajectory analysis
# Parameter: Visual perception delay time (baseParameters, etc.)
# Measurement: Collision times from trajectory simulations
trajectory_df <- data.frame(
  base_delay_time = real_data$baseParameters,
  truthy_delay_time = real_data$truthyParameters,
  random_delay_time = real_data$randomParameters,
  base_collision_times = real_data$baseLog.collisionTimes,
  truthy_collision_times = real_data$truthyLog.collisionTimes,
  random_collision_times = real_data$randomLog.collisionTimes
)

# Remove any rows with missing data
trajectory_df <- trajectory_df[complete.cases(trajectory_df), ]

cat("Real trajectory analysis setup complete\n")
cat("Dataset contains", nrow(trajectory_df), "simulation runs\n")
cat("Parameter: Visual perception delay time\n")
cat("  Range:", round(min(trajectory_df$base_delay_time), 3), "to", round(max(trajectory_df$base_delay_time), 3), "\n")
cat("Measurement: Collision times from trajectory simulations\n")
cat("  Range:", round(min(trajectory_df$base_collision_times), 1), "to", round(max(trajectory_df$base_collision_times), 1), "\n")
