library(here)
source(here("examples", "02_uncontrolled_example.R"))

# Compute difference variables for plotting
same_param_diff <- uncontrolled_df$base_h - uncontrolled_df$truthy_h
random_param_diff <- uncontrolled_df$base_h - uncontrolled_df$random_h
same_param_variance <- var(same_param_diff)
random_param_variance <- var(random_param_diff)

par(mfrow=c(2,2))

# Plot 1: Parameter vs Measurement (should show no relationship)
plot(uncontrolled_df$base_params, uncontrolled_df$base_h, 
     main="Parameter vs Measurement (No Control)", 
     xlab="Parameter X", ylab="Measurement H",
     pch=16, cex=0.5, col="blue")
abline(h=15, col="red", lwd=2)  # True relationship (constant)
legend("topleft", c("Data", "True: H = 15"), col=c("blue", "red"), 
       pch=c(16, NA), lty=c(NA, 1))

# Plot 2: Same parameter differences
plot(1:length(same_param_diff), same_param_diff,
     main="Same Parameter Differences", 
     xlab="Sample", ylab="H - H' (same X)",
     pch=16, cex=0.5, col="green")
abline(h=0, col="black", lwd=2)

# Plot 3: Random parameter differences (should be similar to same param)
plot(1:length(random_param_diff), random_param_diff,
     main="Random Parameter Differences", 
     xlab="Sample", ylab="H(X) - H'(X')",
     pch=16, cex=0.5, col="orange")
abline(h=0, col="black", lwd=2)

# Plot 4: Variance comparison (should be nearly equal)
variances <- c(same_param_variance, random_param_variance)
names(variances) <- c("Same Param", "Random Param")
barplot(variances, main="Variance Comparison (Should be Equal)",
        ylab="Variance", col=c("green", "orange"))
text(1:2, variances + max(variances)*0.05, round(variances, 2), 
     pos=3, cex=0.8)

cat("Plot saved as uncontrolled_example_plot.png")
