#' Bootstrap Impact Test for Parameter Influence Assessment
#'
#' Implements Algorithm 3: Bootstrap Significance Test from the variance
#' decomposition theory. This function assesses whether input parameters have
#' statistically significant influence on simulation outputs by comparing
#' variance of same-parameter replicates vs. random-parameter replicates.
#'
#' @param H_same Numeric vector of measurements from identical parameter replications
#'               (base experiment paired with truthy/identical replica)
#' @param H_rand Numeric vector of measurements from random parameter replications
#'               (base experiment paired with random parameter replica)
#' @param conf.level Confidence level for bootstrap percentile confidence interval
#'                   (default: 0.95 for 95% CI)
#' @param B Number of bootstrap iterations (default: 1000)
#' @param alternative Character string specifying the alternative hypothesis.
#'                    Must be one of "greater" (default), "two.sided", or "less".
#'                    "greater" tests if impact > 0 (parameter has positive influence)
#'
#' @return A list with class "htest" containing:
#' \describe{
#'   \item{impact}{Observed impact variance (Var(Y_rand) - Var(Y_same))}
#'   \item{var_same}{Variance of same-parameter differences (noise baseline)}
#'   \item{var_rand}{Variance of random-parameter differences (noise + signal)}
#'   \item{effect_size}{Normalized effect size (impact / var_same)}
#'   \item{p.value}{Bootstrap p-value for the hypothesis test}
#'   \item{conf.int}{Bootstrap percentile confidence interval for impact}
#'   \item{alternative}{Description of alternative hypothesis}
#'   \item{data.name}{Names of the input data vectors}
#'   \item{method}{Description of the statistical method}
#'   \item{statistic}{Named numeric vector with the impact statistic}
#' }
#'
#' @details
#' The function implements the variance decomposition approach based on the
#' law of total variance. It computes:
#'
#' 1. Y_same = H_same[1] - H_same[2] for each pair (measurement noise only)
#' 2. Y_rand = H_rand[1] - H_rand[2] for each pair (noise + parameter effect)
#' 3. Impact = Var(Y_rand) - Var(Y_same) (parameter influence component)
#'
#' The bootstrap procedure:
#' - Resamples paired observations with replacement
#' - Computes impact for each bootstrap sample
#' - Forms percentile confidence interval
#' - Calculates p-value based on proportion of bootstrap impacts <= 0
#'
#' Interpretation:
#' - impact > 0: Parameters influence measurements
#' - impact ≈ 0: No parameter influence detected
#' - effect_size: Normalized measure (impact relative to noise)
#'
#' @references
#' Theory document: "Variance Decomposition Analysis for Simulation
#' Parameter Impact Assessment"
#'
#' @examples
#' # Generate example data
#' n <- 1000
#' # Same parameter replicates (pure noise)
#' H_same_1 <- rnorm(n, mean = 10, sd = 2)
#' H_same_2 <- rnorm(n, mean = 10, sd = 2)
#' H_same <- cbind(H_same_1, H_same_2)
#'
#' # Random parameter replicates (noise + parameter effect)
#' params <- runif(n, 0, 1)
#' H_rand_1 <- rnorm(n, mean = 10 + 5 * params, sd = 2)
#' H_rand_2 <- rnorm(n, mean = 10 + 5 * runif(n, 0, 1), sd = 2)
#' H_rand <- cbind(H_rand_1, H_rand_2)
#'
#' # Run bootstrap test
#' result <- bootstrap_impact_test(H_same, H_rand, conf.level = 0.95, B = 1000)
#' print(result)
#'
#' @export
bootstrap_impact_test <- function(H_same, H_rand, conf.level = 0.95,
                                  B = 1000, alternative = "greater") {
  # Input validation
  if (!is.numeric(H_same) || !is.numeric(H_rand)) {
    stop("H_same and H_rand must be numeric vectors or matrices")
  }

  # Validate alternative hypothesis
  alternative <- match.arg(alternative, c("greater", "two.sided", "less"))

  # Convert to matrices if needed and check dimensions
  if (is.vector(H_same)) {
    if (length(H_same) %% 2 != 0) {
      stop("H_same must have even length (pairs of measurements)")
    }
    H_same <- matrix(H_same, ncol = 2, byrow = TRUE)
  }

  if (is.vector(H_rand)) {
    if (length(H_rand) %% 2 != 0) {
      stop("H_rand must have even length (pairs of measurements)")
    }
    H_rand <- matrix(H_rand, ncol = 2, byrow = TRUE)
  }

  # Check that both have 2 columns
  if (ncol(H_same) != 2 || ncol(H_rand) != 2) {
    stop("H_same and H_rand must have exactly 2 columns (paired measurements)")
  }

  # Check sample sizes match
  n <- nrow(H_same)
  if (nrow(H_rand) != n) {
    stop("H_same and H_rand must have the same number of rows (sample size)")
  }

  # Validate confidence level
  if (conf.level <= 0 || conf.level >= 1) {
    stop("conf.level must be between 0 and 1")
  }

  # Validate bootstrap iterations
  if (B < 100) {
    warning("B < 100: Consider using more bootstrap iterations for reliable results")
  }

  # Store data names for output
  data_name <- paste(deparse(substitute(H_same)), "and",
    deparse(substitute(H_rand)),
    sep = " "
  )

  # Step 1: Compute difference variables
  # Y_same = H1 - H2 for identical parameters (pure noise)
  # Y_rand = H1 - H2 for random parameters (noise + parameter effect)
  Y_same <- H_same[, 1] - H_same[, 2]
  Y_rand <- H_rand[, 1] - H_rand[, 2]

  # Step 2: Compute observed quantities
  var_same <- var(Y_same)
  var_rand <- var(Y_rand)
  impact_obs <- var_rand - var_same

  # Compute effect size (normalized by noise baseline)
  effect_size <- impact_obs / var_same

  # Step 3: Bootstrap procedure
  # Initialize array for bootstrap impact estimates
  impact_boot <- numeric(B)

  # Set seed for reproducibility (optional - user can set.seed before calling)
  # We don't set seed here to allow user control

  # Bootstrap loop
  for (b in 1:B) {
    # Sample with replacement: indices for paired observations
    indices <- sample(1:n, size = n, replace = TRUE)

    # Create bootstrap samples (maintaining pairing structure)
    Y_same_boot <- Y_same[indices]
    Y_rand_boot <- Y_rand[indices]

    # Compute bootstrap impact
    var_same_boot <- var(Y_same_boot)
    var_rand_boot <- var(Y_rand_boot)
    impact_boot[b] <- var_rand_boot - var_same_boot
  }

  # Step 4: Compute confidence interval
  alpha <- 1 - conf.level

  if (alternative == "two.sided") {
    # Two-sided confidence interval
    ci_lower <- quantile(impact_boot, alpha / 2)
    ci_upper <- quantile(impact_boot, 1 - alpha / 2)
  } else if (alternative == "greater") {
    # One-sided: impact > 0
    ci_lower <- quantile(impact_boot, alpha)
    ci_upper <- Inf
  } else {
    # One-sided: impact < 0
    ci_lower <- -Inf
    ci_upper <- quantile(impact_boot, 1 - alpha)
  }

  conf_int <- c(ci_lower, ci_upper)
  attr(conf_int, "conf.level") <- conf.level

  # Step 5: Compute p-value
  if (alternative == "greater") {
    # H0: Impact <= 0, H1: Impact > 0
    # P-value = proportion of bootstrap impacts <= 0
    p_value <- mean(impact_boot <= 0)
  } else if (alternative == "less") {
    # H0: Impact >= 0, H1: Impact < 0
    # P-value = proportion of bootstrap impacts >= 0
    p_value <- mean(impact_boot >= 0)
  } else {
    # Two-sided: H0: Impact = 0, H1: Impact != 0
    # P-value = 2 * min(P(impact <= 0), P(impact >= 0))
    p_lower <- mean(impact_boot <= 0)
    p_upper <- mean(impact_boot >= 0)
    p_value <- 2 * min(p_lower, p_upper)
  }

  # Ensure p-value is in [0, 1]
  p_value <- min(max(p_value, 0), 1)

  # Create result list with htest structure
  result <- list(
    statistic = c(impact = impact_obs),
    parameter = c(bootstrap_iterations = B),
    p.value = p_value,
    conf.int = conf_int,
    estimate = c(
      impact = impact_obs,
      var_same = var_same,
      var_rand = var_rand,
      effect_size = effect_size
    ),
    null.value = c(impact = 0),
    alternative = alternative,
    method = "Bootstrap Impact Test for Parameter Influence",
    data.name = data_name,
    # Additional components for compatibility with requested output format
    impact = impact_obs,
    var_same = var_same,
    var_rand = var_rand,
    effect_size = effect_size
  )

  class(result) <- "htest"
  return(result)
}


#' Print method for bootstrap impact test
#'
#' @param x An object of class "htest" from bootstrap_impact_test
#' @param ... Additional arguments (ignored)
#' @export
print.bootstrap_impact_test <- function(x, ...) {
  cat("\n")
  cat(strwrap(x$method, prefix = "\t"), sep = "\n")
  cat("\n")
  cat("data: ", x$data.name, "\n", sep = "")
  cat("impact = ", format(x$impact, digits = 4), sep = "")
  cat(", p-value = ", format(x$p.value, digits = 4), "\n", sep = "")

  cat("alternative hypothesis: ")
  if (x$alternative == "greater") {
    cat("true impact is greater than 0\n")
  } else if (x$alternative == "less") {
    cat("true impact is less than 0\n")
  } else {
    cat("true impact is not equal to 0\n")
  }

  conf_level <- attr(x$conf.int, "conf.level")
  cat(format(100 * conf_level), " percent confidence interval:\n", sep = "")
  cat(" ", format(x$conf.int[1], digits = 4), " ",
    format(x$conf.int[2], digits = 4), "\n",
    sep = ""
  )

  cat("sample estimates:\n")
  cat(" impact variance: ", format(x$impact, digits = 4), "\n", sep = "")
  cat(" same-param var:  ", format(x$var_same, digits = 4), "\n", sep = "")
  cat(" random-param var:", format(x$var_rand, digits = 4), "\n", sep = "")
  cat(" effect size:     ", format(x$effect_size, digits = 4), "\n", sep = "")

  invisible(x)
}
