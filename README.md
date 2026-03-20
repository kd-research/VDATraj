# VDA: A Replication-based Variance Decomposition Analysis

Variance decomposition analysis for simulation parameter impact assessment. This project implements a bootstrap-based hypothesis testing framework to determine whether input parameters have statistically significant influence on multi-agent simulation outputs.

## Overview

The core statistical approach compares variance between:
- **Same-parameter replicates** (noise baseline): Var(Y_same)
- **Random-parameter replicates** (noise + parameter signal): Var(Y_rand)
- **Impact** = Var(Y_rand) - Var(Y_same) indicates parameter influence

## Project Structure

```
find-variance/
├── R/                          # Core R modules
│   ├── parsers.R               # Parse log strings, JSON arrays
│   ├── database.R              # SQLite queries and data retrieval
│   ├── preprocessing.R         # Unnest nested columns for analysis
│   └── variance_analysis.R     # bootstrap_impact_test() statistical engine
├── docs/                       # Literate programming documents
│   ├── theory.org              # Theoretical foundation and algorithms
│   ├── verification.org        # Controlled experiments validating the method
│   ├── comprehensive_evaluation.org  # Full parameter evaluation results
│   ├── theory/                 # Tangled R scripts from theory.org
│   ├── verification/           # Tangled R scripts from verification.org
│   └── comprehensive_evaluation/     # Tangled R scripts from comprehensive_evaluation.org
├── examples/                   # Standalone example scripts
│   ├── common_header.R         # Standard imports for all examples
│   ├── 01_controlled_example.R # Linear control experiment
│   ├── 02_uncontrolled_example.R   # No-control experiment
│   ├── 03_sinusoidal_example.R     # Non-linear relationship test
│   ├── 04_trajectory_example.R     # Real trajectory data analysis
│   └── comprehensive_analysis_setup.R  # Setup for full evaluation
├── tests/                      # Unit tests (testthat)
├── outputs/                    # Generated plots and results
│   ├── plots/                  # Visualization outputs
│   └── extern/                 # External outputs
├── data/                       # SQLite databases (download from Google Drive)
├── flake.nix                   # Nix flake for reproducible environment
├── shell.nix                   # Legacy nix-shell support
└── test.sh                     # Test runner script
```

## Reproduction Methods

### Method 1: Native Reproduction (Nix + Emacs)

This is the recommended approach for full reproducibility. The project uses:
- **Nix** for declarative, reproducible R environment
- **Emacs Org-mode** as the document host
- **Org-babel** for literate programming and code evaluation

#### Prerequisites

1. Install [Nix](https://nixos.org/download.html) with flakes enabled
2. Install Emacs with Org-mode (version 9.0+)

#### Setup

```bash
# Clone the repository
git clone <repository-url>
cd find-variance

# Set up data directory (see Data section below)
rm -f data  # Remove symlink if exists
mkdir -p data
# Download SQLite databases from Google Drive and place in data/

# Enter the development environment
# Option 1: Using direnv (recommended)
direnv allow

# Option 2: Manual nix shell
nix develop

# Option 3: Legacy nix-shell
nix-shell
```

#### Running in Emacs

1. Open any `.org` file in the `docs/` directory with Emacs
2. The org files are configured with local variables to use the Nix R environment:
   ```elisp
   # Local Variables:
   # org-babel-R-command: "nix run . -- --slave --no-save"
   # END:
   ```

3. Evaluate code blocks:
   - Single block: Place cursor in block and press `C-c C-c`
   - All blocks: `C-c C-v b` (org-babel-execute-buffer)
   - Export with evaluation: `C-c C-e` then choose format

4. Tangle R scripts to separate files:
   - Single file: `C-c C-v t` (org-babel-tangle)
   - This extracts all source blocks to `docs/<org-name>/*.R`

#### Running Tests

```bash
# Using the test script
./test.sh

# Or directly with Nix
nix run . -- tests/run_unit_tests.R

# Or run Nix checks
nix flake check
```

### Method 2: Empirical Reproduction (Manual R Setup)

For users without Nix or Emacs, you can reproduce results by running the pre-tangled R scripts directly. All tangled scripts are committed to the repository.

#### Prerequisites

1. R (version 4.0+)
2. Required R packages

#### R Environment Setup

```r
# Install required packages
install.packages(c(
  "RSQLite",
  "jsonlite",
  "dplyr",
  "tidyr",
  "purrr",
  "here",
  "DBI",
  "ggplot2",
  "testthat"
))
```

#### Pre-Tangled Scripts

All R scripts extracted from org files are committed to the repository in:
- `docs/theory/` - 10 scripts from theory.org
- `docs/verification/` - 13 scripts from verification.org
- `docs/comprehensive_evaluation/` - 14 scripts from comprehensive_evaluation.org

#### Running Tangled Scripts

All scripts should be run from the **project root directory** to ensure the `here` package resolves paths correctly.

```bash
cd find-variance  # project root

# Run verification experiments
Rscript docs/verification/setup_controlled_example.R
Rscript docs/verification/controlled_analysis.R
Rscript docs/verification/setup_uncontrolled_example.R
Rscript docs/verification/uncontrolled_analysis.R
Rscript docs/verification/setup_sinusoidal_example.R
Rscript docs/verification/sinusoidal_analysis.R
Rscript docs/verification/setup_trajectory_example.R
Rscript docs/verification/trajectory_analysis.R
Rscript docs/verification/summary_comparison.R

# Run theory examples
Rscript docs/theory/dataframe_description.R
Rscript docs/theory/base_variation.R
Rscript docs/theory/replica_variation.R
Rscript docs/theory/random_variation.R
Rscript docs/theory/impact_variance_calculation.R

# Run comprehensive evaluation (requires data)
Rscript docs/comprehensive_evaluation/hetero_time_enabled.R
Rscript docs/comprehensive_evaluation/significance_summary.R
# ... and other evaluation scripts
```

#### Running Standalone Examples

The `examples/` directory contains self-contained scripts that can be run directly:

```bash
cd find-variance  # project root

# Run individual examples
Rscript examples/01_controlled_example.R
Rscript examples/02_uncontrolled_example.R
Rscript examples/03_sinusoidal_example.R
Rscript examples/04_trajectory_example.R

# Run all verifications
Rscript examples/run_all_verifications.R
```

#### Running Unit Tests

```bash
cd find-variance
Rscript tests/run_unit_tests.R
```

## Data

The processed simulation data (SQLite databases) is available on Google Drive:

**Download link:** [Google Drive - cog-merged.tar.xz](https://drive.google.com/file/d/18oVylf5ZnFshUNEOTzTCPEv0EXBIfVvU/view?usp=sharing)

### Setup

```bash
# Remove the symlink (if exists)
rm -f data

# Download cog-merged.tar.xz from Google Drive, extract, and rename
tar -xJf cog-merged.tar.xz
mv cog-merged data
```

### Database Schema

The SQLite databases contain:
- `parameters` - simulation parameter definitions
- `parameter_relations` - parameter relationships
- `benchmark_log` - simulation output logs

## Key Function

The core statistical engine is `bootstrap_impact_test()` in `R/variance_analysis.R`:

```r
bootstrap_impact_test(
  H_same,           # Same-parameter differences
  H_rand,           # Random-parameter differences
  conf.level = 0.95,
  B = 1000,         # Bootstrap iterations
  alternative = "greater"
)
```

Returns an `htest`-class object with impact estimate, effect size, p-value, and confidence intervals.

## Documentation

- `docs/theory.org` - Mathematical foundation and algorithm descriptions
- `docs/verification.org` - Controlled experiments validating the method
- `docs/comprehensive_evaluation.org` - Full parameter evaluation across all datasets

## License

See LICENSE file for details.
