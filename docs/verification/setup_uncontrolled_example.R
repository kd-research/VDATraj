library(here)
source(here("examples", "02_uncontrolled_example.R"))

# Data already loaded by prelude/uncontrolled_example.R
print("Uncontrolled example data loaded from prelude")
print(paste("Number of samples:", nrow(uncontrolled_df)))
print(paste("Parameter range:", min(uncontrolled_df$base_params), "to", max(uncontrolled_df$base_params)))
print("True relationship: h(x) = 15 + N(0, 4) (CONSTANT!)")
print("Data structure:")
str(uncontrolled_df)
