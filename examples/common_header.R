suppressPackageStartupMessages(library(dplyr))
suppressPackageStartupMessages(library(tidyr))
suppressPackageStartupMessages(library(purrr))
suppressPackageStartupMessages(library(RSQLite))
suppressPackageStartupMessages(library(jsonlite))

# Determine the project root directory
# This script should be in examples/, so go up one level
script_dir <- if (exists("ofile") && !is.null(ofile)) {
  dirname(ofile)
} else {
  # Fallback: check if we're in examples or project root
  if (dir.exists("../R") && file.exists("../R/parsers.R")) {
    "."  # We're in examples/
  } else if (dir.exists("R") && file.exists("R/parsers.R")) {
    ".."  # Would need to go up, but we're already at root
  } else {
    stop("Cannot determine project root directory")
  }
}

# Source R modules from project root
# If we're in examples/, R modules are in ../R/
# If we're in project root, R modules are in R/
r_dir <- if (dir.exists("../R") && file.exists("../R/parsers.R")) {
  "../R"
} else if (dir.exists("R") && file.exists("R/parsers.R")) {
  "R"
} else {
  stop("Cannot find R module directory")
}

source(file.path(r_dir, "parsers.R"))
source(file.path(r_dir, "database.R"))
source(file.path(r_dir, "preprocessing.R"))
source(file.path(r_dir, "variance_analysis.R"))
