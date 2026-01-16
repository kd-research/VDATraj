source("examples/comprehensive_analysis_setup.R")

# Run all 8 analyses in parallel
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
  label <- measure_labels[measure_idx]
  
  results <- analyze_all_parameters_cached(
    sim_type = sim_type,
    measure_column = measure,
    data_dir = "data",
    B = 1000,
    conf.level = 0.95,
    cache_dir = ".localfiles"
  )
  
  # Create column name combining sim_type and measurement
  col_name <- paste0(substring(sim_type, 1, 4), ".", label)
  
  # Extract only Parameter and Is.Significant
  results_subset <- results %>%
    select(Parameter, P_Value) %>%
    mutate(!!col_name := if_else(P_Value < 0.05, "YES", "NO")) %>%
    select(Parameter, !!col_name)
  
  return(results_subset)
}

# Run in parallel
n_cores <- max(1, parallel::detectCores() - 1)
all_results <- parallel::mclapply(
  seq_len(nrow(combinations)),
  process_combination,
  mc.cores = n_cores
)

# Merge all results by Parameter
significance_table <- all_results[[1]]
for (i in 2:length(all_results)) {
  significance_table <- merge(significance_table, all_results[[i]], by = "Parameter", all = TRUE)
}

# Transpose: make parameters as columns and categories as rows
significance_table_transposed <- significance_table %>%
  arrange(Parameter) %>%
  pivot_longer(cols = -Parameter, names_to = "Category", values_to = "Significant") %>%
  pivot_wider(names_from = Parameter, values_from = Significant, names_prefix = "P.")

# Reorder categories logically (heterogeneous first, then homogeneous)
category_order <- c(
  "hete.Time.Enabled", "hete.Collision.Times", "hete.Distance.Traveled", "hete.PLE.Energy",
  "homo.Time.Enabled", "homo.Collision.Times", "homo.Distance.Traveled", "homo.PLE.Energy"
)

significance_table_transposed <- significance_table_transposed %>%
  mutate(Category = factor(Category, levels = category_order)) %>%
  arrange(Category) %>%
  mutate(Category = as.character(Category))

significance_table_transposed
