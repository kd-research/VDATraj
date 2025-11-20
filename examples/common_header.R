suppressPackageStartupMessages(library(dplyr))
suppressPackageStartupMessages(library(tidyr))
suppressPackageStartupMessages(library(purrr))
suppressPackageStartupMessages(library(RSQLite))
suppressPackageStartupMessages(library(jsonlite))

# Use here package for path-independent sourcing
# The here package automatically finds the project root by looking for
# .git, .Rproj files, or other project markers
if (!require("here", quietly = TRUE)) {
  install.packages("here")
  library(here)
}

# Source R modules from project root
# here::here() automatically resolves paths relative to project root
# regardless of the current working directory
source(here::here("R", "parsers.R"))
source(here::here("R", "database.R"))
source(here::here("R", "preprocessing.R"))
source(here::here("R", "variance_analysis.R"))
