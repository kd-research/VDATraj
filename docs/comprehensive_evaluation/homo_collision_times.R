source("examples/comprehensive_analysis_setup.R")

# Analyze all parameters for homogeneous simulations - collision times
results <- analyze_all_parameters_cached(
  sim_type = "homogeneous",
  measure_column = "baseLog.collisionTimes",
  data_dir = "data",
  B = 1000,
  conf.level = 0.95,
  cache_dir = ".localfiles"
)

results %>%
  select(Parameter, Impact, Effect_Size, P_Value, CI_Lower) %>%
  rename(Effect.Size = Effect_Size, P.Value = P_Value, CI.Lower = CI_Lower) %>%
  round(digit=4) %>%
  mutate(Is.Significant = if_else(P.Value < 0.05, "YES:--", "---:NO")) %>%
  rename(Is.Significant = Is.Significant)
