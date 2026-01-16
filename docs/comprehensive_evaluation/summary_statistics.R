source("examples/comprehensive_analysis_setup.R")

# Combine all results for comparative analysis using parallel processing
sim_types <- c("heterogeneous", "homogeneous")
measures <- c(
  "baseLog.agent_time_enableds",
  "baseLog.collisionTimes",
  "baseLog.agent_distance_traveleds",
  "baseLog.agent_ple_energys"
)

measure_labels <- c(
  "Time.Enabled",
  "Collision.Times",
  "Distance.Traveled",
  "PLE.Energy"
)

# Create all combinations of sim_type and measure
combinations <- expand.grid(
  sim_type = sim_types,
  measure_idx = seq_along(measures),
  stringsAsFactors = FALSE
)

# Parallel processing function
process_combination <- function(i) {
  sim_type <- combinations$sim_type[i]
  measure_idx <- combinations$measure_idx[i]
  measure <- measures[measure_idx]
  label <- measure_labels[measure_idx]
  
  results <- analyze_all_parameters_cached(
    sim_type = sim_type,
    measure_column = measure,
    data_dir = "data",
    B = 100,  # Reduced for summary computation
    conf.level = 0.95,
    cache_dir = ".localfiles"
  )
  
  results$Sim_Type <- sim_type
  results$Measurement <- label
  
  return(results)
}

# Run in parallel
n_cores <- max(1, parallel::detectCores() - 1)
all_results <- parallel::mclapply(
  seq_len(nrow(combinations)),
  process_combination,
  mc.cores = n_cores
)

# Combine all results
combined_df <- do.call(rbind, all_results)

# Calculate summary statistics
summary_df <- combined_df %>%
  group_by(Sim_Type, Measurement) %>%
  summarise(
    N.Sgnf = sum(P_Value < 0.05, na.rm = TRUE),
    Mean.Impact = mean(Impact, na.rm = TRUE),
    Mean.Effect.Size = mean(Effect_Size, na.rm = TRUE),
    Max.Effect.Size = max(Effect_Size, na.rm = TRUE),
    .groups = "drop"
  ) %>%
  arrange(desc(Mean.Effect.Size)) %>%
  mutate(across(where(is.numeric), ~round(., digits=4))) %>%
  rename(Sim.Type = Sim_Type)

summary_df
