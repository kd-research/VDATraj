source("examples/comprehensive_analysis_setup.R")

# Rank parameters by their average impact across all measurements and simulation types
# Using parallel processing
sim_types <- c("heterogeneous", "homogeneous")
measures <- c(
  "baseLog.agent_time_enableds",
  "baseLog.collisionTimes",
  "baseLog.agent_distance_traveleds",
  "baseLog.agent_ple_energys"
)

# Create all combinations
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
  
  results <- analyze_all_parameters_cached(
    sim_type = sim_type,
    measure_column = measure,
    data_dir = "data",
    B = 100,  # Reduced for ranking computation
    conf.level = 0.95,
    cache_dir = ".localfiles"
  )
  
  results$Sim_Type <- sim_type
  results$Measurement <- measure
  
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

# Calculate average metrics per parameter across sim types
parameter_ranking <- combined_df %>%
  group_by(Parameter, Sim_Type) %>%
  summarise(
    N.Sgnf = sum(P_Value < 0.05, na.rm = TRUE),
    Avg.Impact = mean(Impact, na.rm = TRUE),
    Avg.Effect.Size = mean(Effect_Size, na.rm = TRUE),
    Max.Effect.Size = max(Effect_Size, na.rm = TRUE),
    .groups = "drop"
  ) %>%
  arrange(desc(Avg.Effect.Size)) %>%
  mutate(across(where(is.numeric), ~round(., digits=4))) %>%
  rename(Sim.Type = Sim_Type)

parameter_ranking
