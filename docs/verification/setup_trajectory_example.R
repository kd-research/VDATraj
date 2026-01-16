library(here)
source(here("examples", "04_trajectory_example.R"))

# Data already loaded by prelude/trajectory_example.R  
print("Real trajectory analysis data loaded from prelude")
print(paste("Number of simulation runs:", nrow(trajectory_df)))
print(paste("Visual perception delay time range:", round(min(trajectory_df$base_delay_time), 3), "to", round(max(trajectory_df$base_delay_time), 3)))
print("Measurement: Collision times from trajectory simulations")
print("Research question: Does visual perception delay time influence collision outcomes?")
print("Data structure:")
str(trajectory_df)
