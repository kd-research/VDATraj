# Unit tests for variance_analysis.R
# Tests bootstrap impact test for parameter influence assessment

suppressPackageStartupMessages(library(testthat))

# Source dependencies if not already loaded (for standalone test runs)
if (!exists("bootstrap_impact_test")) {
  # Try to source from tests/setup.R first
  if (file.exists("tests/setup.R")) {
    source("tests/setup.R")
  } else if (file.exists("../../R/variance_analysis.R")) {
    # If running from tests/testthat directory
    source("../../R/variance_analysis.R")
  } else {
    # If running from project root
    source("R/variance_analysis.R")
  }
}

# Test 1: Test with known data structure
# Verify correct calculation of impact, var_same, var_rand with simple synthetic data
test_that("bootstrap_impact_test calculates variances correctly with known data", {
  # Create simple synthetic data with known properties
  set.seed(123)
  n <- 500

  # Same parameter: pure noise (mean = 10, sd = 2)
  H_same_1 <- rnorm(n, mean = 10, sd = 2)
  H_same_2 <- rnorm(n, mean = 10, sd = 2)
  H_same <- cbind(H_same_1, H_same_2)

  # Random parameter: noise + parameter effect
  # Parameters vary uniformly, adding 0-5 to the mean
  params <- runif(n, 0, 1)
  H_rand_1 <- rnorm(n, mean = 10 + 5 * params, sd = 2)
  H_rand_2 <- rnorm(n, mean = 10 + 5 * runif(n, 0, 1), sd = 2)
  H_rand <- cbind(H_rand_1, H_rand_2)

  # Calculate expected values manually
  Y_same <- H_same[, 1] - H_same[, 2]
  Y_rand <- H_rand[, 1] - H_rand[, 2]
  expected_var_same <- var(Y_same)
  expected_var_rand <- var(Y_rand)
  expected_impact <- expected_var_rand - expected_var_same

  # Run the test
  result <- bootstrap_impact_test(H_same, H_rand, conf.level = 0.95, B = 100)

  # Verify calculations
  expect_equal(result$var_same, expected_var_same, tolerance = 1e-10)
  expect_equal(result$var_rand, expected_var_rand, tolerance = 1e-10)
  expect_equal(result$impact, expected_impact, tolerance = 1e-10)
  expect_equal(result$effect_size, expected_impact / expected_var_same, tolerance = 1e-10)
})

# Test 2: Test output structure
# Verify returned object has all required components
test_that("bootstrap_impact_test returns object with all required components", {
  set.seed(456)
  n <- 100

  # Simple test data
  H_same <- cbind(rnorm(n, 10, 2), rnorm(n, 10, 2))
  H_rand <- cbind(rnorm(n, 10, 3), rnorm(n, 10, 3))

  result <- bootstrap_impact_test(H_same, H_rand, conf.level = 0.95, B = 100)

  # Check all required components exist
  expect_true("impact" %in% names(result))
  expect_true("var_same" %in% names(result))
  expect_true("var_rand" %in% names(result))
  expect_true("effect_size" %in% names(result))
  expect_true("p.value" %in% names(result))
  expect_true("conf.int" %in% names(result))
  expect_true("alternative" %in% names(result))
  expect_true("data.name" %in% names(result))

  # Check types
  expect_type(result$impact, "double")
  expect_type(result$var_same, "double")
  expect_type(result$var_rand, "double")
  expect_type(result$effect_size, "double")
  expect_type(result$p.value, "double")
  expect_type(result$conf.int, "double")
  expect_type(result$alternative, "character")
  expect_type(result$data.name, "character")

  # Check that values are finite and valid
  expect_true(is.finite(result$impact))
  expect_true(is.finite(result$var_same))
  expect_true(is.finite(result$var_rand))
  expect_true(is.finite(result$effect_size))
  expect_true(is.finite(result$p.value))
  expect_true(result$p.value >= 0 && result$p.value <= 1)

  # Check confidence interval structure
  expect_equal(length(result$conf.int), 2)
  expect_true("conf.level" %in% names(attributes(result$conf.int)))
  expect_equal(attr(result$conf.int, "conf.level"), 0.95)
})

# Test 3: Test htest class
# Verify result is of class "htest" and compatible with R's standard testing framework
test_that("bootstrap_impact_test returns valid htest object", {
  set.seed(789)
  n <- 100

  H_same <- cbind(rnorm(n, 10, 2), rnorm(n, 10, 2))
  H_rand <- cbind(rnorm(n, 12, 3), rnorm(n, 12, 3))

  result <- bootstrap_impact_test(H_same, H_rand, conf.level = 0.90, B = 100)

  # Check class
  expect_s3_class(result, "htest")

  # Check standard htest components
  expect_true("statistic" %in% names(result))
  expect_true("parameter" %in% names(result))
  expect_true("p.value" %in% names(result))
  expect_true("conf.int" %in% names(result))
  expect_true("estimate" %in% names(result))
  expect_true("null.value" %in% names(result))
  expect_true("alternative" %in% names(result))
  expect_true("method" %in% names(result))
  expect_true("data.name" %in% names(result))

  # Check statistic naming
  expect_named(result$statistic, "impact")

  # Check parameter naming
  expect_named(result$parameter, "bootstrap_iterations")
  expect_equal(result$parameter[["bootstrap_iterations"]], 100)

  # Check estimate contains multiple values
  expect_true(length(result$estimate) >= 4)
  expect_true("impact" %in% names(result$estimate))
  expect_true("var_same" %in% names(result$estimate))
  expect_true("var_rand" %in% names(result$estimate))
  expect_true("effect_size" %in% names(result$estimate))

  # Check null value
  expect_named(result$null.value, "impact")
  expect_equal(result$null.value[["impact"]], 0)

  # Check method string
  expect_true(grepl("Bootstrap Impact Test", result$method))

  # Verify print method works without error
  expect_output(print(result), "Bootstrap Impact Test")
})

# Test 4: Test with no parameter effect
# When H_same and H_rand are statistically identical, impact should be ~0, p-value should be high
test_that("bootstrap_impact_test detects no parameter effect correctly", {
  set.seed(111)
  n <- 500

  # Both same and rand have identical distributions (pure noise, no parameter effect)
  H_same <- cbind(rnorm(n, mean = 20, sd = 3), rnorm(n, mean = 20, sd = 3))
  H_rand <- cbind(rnorm(n, mean = 20, sd = 3), rnorm(n, mean = 20, sd = 3))

  result <- bootstrap_impact_test(H_same, H_rand, conf.level = 0.95, B = 500, alternative = "greater")

  # Impact should be close to zero (within reasonable sampling variation)
  # With n=500, we expect standard error to be small
  expect_true(abs(result$impact) < 2.0) # Generous threshold for sampling variation

  # P-value should be relatively high (not significant) since there's no real effect
  # With no effect, about 50% of bootstrap samples should be <= 0
  # However, due to sampling variation, we use a more lenient threshold
  expect_true(result$p.value > 0.10) # Should be roughly 0.5, but allow more variation

  # Variance of same and rand should be similar
  ratio <- result$var_rand / result$var_same
  expect_true(ratio > 0.8 && ratio < 1.2) # Within 20% of each other

  # Effect size should be small
  expect_true(abs(result$effect_size) < 0.3)

  # Confidence interval should contain 0 for one-sided test
  # For "greater" alternative, lower bound should be negative or close to 0
  expect_true(result$conf.int[1] < 1.0) # Lower bound not strongly positive
})

# Test 5: Test with strong parameter effect
# When H_rand has higher variance, impact should be positive, p-value should be low
test_that("bootstrap_impact_test detects strong parameter effect", {
  set.seed(222)
  n <- 500

  # Same parameter: pure noise (sd = 2)
  H_same <- cbind(rnorm(n, mean = 10, sd = 2), rnorm(n, mean = 10, sd = 2))

  # Random parameter: strong parameter effect
  # Mean varies from 10 to 20 based on parameter (0 to 1)
  params_1 <- runif(n, 0, 1)
  params_2 <- runif(n, 0, 1)
  H_rand <- cbind(
    rnorm(n, mean = 10 + 10 * params_1, sd = 2),
    rnorm(n, mean = 10 + 10 * params_2, sd = 2)
  )

  result <- bootstrap_impact_test(H_same, H_rand, conf.level = 0.95, B = 500, alternative = "greater")

  # Impact should be clearly positive
  expect_true(result$impact > 0)

  # Impact should be substantial (parameter effect adds variance)
  # With strong parameter effect (range 0-10), we expect substantial impact
  expect_true(result$impact > 10) # Conservative threshold

  # P-value should be very small (highly significant)
  expect_true(result$p.value < 0.01)

  # Variance of rand should be larger than same
  expect_true(result$var_rand > result$var_same)

  # Effect size should be substantial
  expect_true(result$effect_size > 0.5)

  # Lower confidence bound should be positive (clear evidence)
  expect_true(result$conf.int[1] > 0)
})

# Test 6: Test bootstrap reproducibility
# With set.seed(), results should be reproducible
test_that("bootstrap_impact_test produces reproducible results with seed", {
  # Create data once with a fixed seed
  set.seed(555)
  n <- 200

  # Generate data with sufficient variation for bootstrap
  H_same <- cbind(rnorm(n, mean = 10, sd = 2), rnorm(n, mean = 10, sd = 2))
  H_rand <- cbind(rnorm(n, mean = 12, sd = 3), rnorm(n, mean = 12, sd = 3))

  # Run test twice with same seed
  set.seed(999)
  result1 <- bootstrap_impact_test(H_same, H_rand, conf.level = 0.95, B = 500)

  set.seed(999)
  result2 <- bootstrap_impact_test(H_same, H_rand, conf.level = 0.95, B = 500)

  # All numeric results should be identical with same seed
  expect_equal(result1$impact, result2$impact)
  expect_equal(result1$var_same, result2$var_same)
  expect_equal(result1$var_rand, result2$var_rand)
  expect_equal(result1$effect_size, result2$effect_size)
  expect_equal(result1$p.value, result2$p.value)
  expect_equal(result1$conf.int, result2$conf.int)
})

# Test 7: Test invalid conf.level
# Must be between 0 and 1
test_that("bootstrap_impact_test validates conf.level parameter", {
  n <- 50
  H_same <- cbind(rnorm(n), rnorm(n))
  H_rand <- cbind(rnorm(n), rnorm(n))

  # conf.level must be between 0 and 1
  expect_error(
    bootstrap_impact_test(H_same, H_rand, conf.level = 0, B = 100),
    "conf.level must be between 0 and 1"
  )

  expect_error(
    bootstrap_impact_test(H_same, H_rand, conf.level = 1, B = 100),
    "conf.level must be between 0 and 1"
  )

  expect_error(
    bootstrap_impact_test(H_same, H_rand, conf.level = -0.05, B = 100),
    "conf.level must be between 0 and 1"
  )

  expect_error(
    bootstrap_impact_test(H_same, H_rand, conf.level = 1.05, B = 100),
    "conf.level must be between 0 and 1"
  )

  expect_error(
    bootstrap_impact_test(H_same, H_rand, conf.level = 95, B = 100),
    "conf.level must be between 0 and 1"
  )

  # Valid conf.levels should work
  expect_silent(bootstrap_impact_test(H_same, H_rand, conf.level = 0.95, B = 100))
  expect_silent(bootstrap_impact_test(H_same, H_rand, conf.level = 0.90, B = 100))
  expect_silent(bootstrap_impact_test(H_same, H_rand, conf.level = 0.99, B = 100))
  expect_silent(bootstrap_impact_test(H_same, H_rand, conf.level = 0.5, B = 100))
})

# Additional test: Test different confidence levels produce expected CI widths
test_that("bootstrap_impact_test produces narrower CIs for higher confidence levels", {
  set.seed(333)
  n <- 200
  H_same <- cbind(rnorm(n, 10, 2), rnorm(n, 10, 2))
  H_rand <- cbind(rnorm(n, 12, 3), rnorm(n, 12, 3))

  # Higher confidence level should produce wider confidence intervals
  result_90 <- bootstrap_impact_test(H_same, H_rand, conf.level = 0.90, B = 500, alternative = "two.sided")
  result_95 <- bootstrap_impact_test(H_same, H_rand, conf.level = 0.95, B = 500, alternative = "two.sided")
  result_99 <- bootstrap_impact_test(H_same, H_rand, conf.level = 0.99, B = 500, alternative = "two.sided")

  # Calculate CI widths
  width_90 <- result_90$conf.int[2] - result_90$conf.int[1]
  width_95 <- result_95$conf.int[2] - result_95$conf.int[1]
  width_99 <- result_99$conf.int[2] - result_99$conf.int[1]

  # Higher confidence should produce wider intervals
  expect_true(width_95 > width_90)
  expect_true(width_99 > width_95)

  # All should contain the observed impact
  expect_true(result_90$conf.int[1] <= result_90$impact && result_90$impact <= result_90$conf.int[2])
  expect_true(result_95$conf.int[1] <= result_95$impact && result_95$impact <= result_95$conf.int[2])
  expect_true(result_99$conf.int[1] <= result_99$impact && result_99$impact <= result_99$conf.int[2])
})

# Additional test: Verify alternative hypotheses work correctly
test_that("bootstrap_impact_test handles different alternative hypotheses", {
  set.seed(444)
  n <- 200
  H_same <- cbind(rnorm(n, 10, 2), rnorm(n, 10, 2))
  H_rand <- cbind(rnorm(n, 12, 3), rnorm(n, 12, 3))

  result_greater <- bootstrap_impact_test(H_same, H_rand, conf.level = 0.95, B = 500, alternative = "greater")
  result_two_sided <- bootstrap_impact_test(H_same, H_rand, conf.level = 0.95, B = 500, alternative = "two.sided")
  result_less <- bootstrap_impact_test(H_same, H_rand, conf.level = 0.95, B = 500, alternative = "less")

  # Check alternative is stored correctly
  expect_equal(result_greater$alternative, "greater")
  expect_equal(result_two_sided$alternative, "two.sided")
  expect_equal(result_less$alternative, "less")

  # Check confidence intervals have correct structure
  # Greater: lower bound finite, upper bound Inf
  expect_true(is.finite(result_greater$conf.int[1]))
  expect_true(is.infinite(result_greater$conf.int[2]))

  # Two-sided: both bounds finite
  expect_true(is.finite(result_two_sided$conf.int[1]))
  expect_true(is.finite(result_two_sided$conf.int[2]))

  # Less: lower bound -Inf, upper bound finite
  expect_true(is.infinite(result_less$conf.int[1]))
  expect_true(is.finite(result_less$conf.int[2]))

  # P-values should be different for different alternatives
  # For positive impact with positive effect, "greater" should have smallest p-value
  if (result_greater$impact > 0) {
    expect_true(result_greater$p.value < result_less$p.value)
  }
})
