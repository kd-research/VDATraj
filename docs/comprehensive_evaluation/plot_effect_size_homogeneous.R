source("examples/comprehensive_analysis_setup.R")
library(ggplot2)
library(dplyr)

# Define measurements
measures <- c(
  "baseLog.agent_time_enableds",
  "baseLog.collisionTimes",
  "baseLog.agent_distance_traveleds",
  "baseLog.agent_ple_energys"
)

measure_labels <- c(
  "Time Enabled",
  "Collision Times",
  "Distance Traveled",
  "PLE Energy"
)

# Load all data for homogeneous simulations
all_data <- list()
for (i in seq_along(measures)) {
  results <- analyze_all_parameters_cached(
    sim_type = "homogeneous",
    measure_column = measures[i],
    data_dir = "data",
    B = 1000,
    conf.level = 0.95,
    cache_dir = ".localfiles"
  ) %>%
    mutate(Measurement = measure_labels[i]) %>%
    select(Parameter, Effect_Size, P_Value, Measurement)
  
  all_data[[i]] <- results
}

# Combine all data
combined_data <- bind_rows(all_data) %>%
  mutate(
    Parameter = factor(Parameter),
    Measurement = factor(Measurement, levels = measure_labels)
  )

# Create grouped bar plot
p <- ggplot(combined_data, aes(fill = Measurement, y = Effect_Size, x = Parameter)) + 
  geom_bar(position = "dodge", stat = "identity") +
  geom_hline(yintercept = 0, linetype = "dashed", color = "gray40", linewidth = 0.5) +
  scale_fill_manual(
    values = c(
      "Time Enabled" = "#E63946",
      "Collision Times" = "#F77F00",
      "Distance Traveled" = "#06A77D",
      "PLE Energy" = "#457B9D"
    ),
    name = "Measurement"
  ) +
  labs(
    title = "Effect Size Comparison: Homogeneous Simulations",
    subtitle = "Grouped by Parameter Index Across All Measurements",
    x = "Parameter Index",
    y = "Effect Size"
  ) +
  theme_minimal(base_size = 14) +
  theme(
    plot.title = element_text(face = "bold", hjust = 0.5, size = 18),
    plot.subtitle = element_text(hjust = 0.5, size = 14),
    legend.position = "bottom",
    legend.title = element_text(face = "bold", size = 13),
    legend.text = element_text(size = 12),
    panel.grid.minor = element_blank(),
    panel.grid.major.x = element_blank(),
    axis.text.x = element_text(size = 12),
    axis.text.y = element_text(size = 12),
    axis.title = element_text(size = 13, face = "bold")
  )

print(p)
