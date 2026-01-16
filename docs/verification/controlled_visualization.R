library(here)
source(here("examples", "01_controlled_example.R"))

# Compute difference variables for plotting
same_param_differences <- controlled_df$base_h - controlled_df$truthy_h
random_param_differences <- controlled_df$base_h - controlled_df$random_h
same_param_variance <- var(same_param_differences)
random_param_variance <- var(random_param_differences)

par(mfrow=c(2,2))

# Plot 1: Parameter vs Measurement relationship
plot(controlled_df$base_params, controlled_df$base_h, 
     main="Parameter vs Measurement", 
     xlab="Parameter X", ylab="Measurement H",
     pch=16, cex=0.5, col="blue")
abline(5, 2, col="red", lwd=2)  # True relationship
legend("topleft", c("Data", "True: H = 2X + 5"), col=c("blue", "red"), 
       pch=c(16, NA), lty=c(NA, 1))

# Plot 2: Same parameter differences (should be pure noise)
plot(1:length(same_param_differences), same_param_differences,
     main="Same Parameter Differences", 
     xlab="Sample", ylab="H - H' (same X)",
     pch=16, cex=0.5, col="green")
abline(h=0, col="black", lwd=2)

# Plot 3: Random parameter differences (noise + signal)
plot(1:length(random_param_differences), random_param_differences,
     main="Random Parameter Differences", 
     xlab="Sample", ylab="H(X) - H'(X')",
     pch=16, cex=0.5, col="orange")
abline(h=0, col="black", lwd=2)

# Plot 4: Variance comparison
variances <- c(same_param_variance, random_param_variance)
names(variances) <- c("Same Param", "Random Param")
barplot(variances, main="Variance Comparison",
        ylab="Variance", col=c("green", "orange"))
text(1:2, variances + max(variances)*0.05, round(variances, 2), 
     pos=3, cex=0.8)

cat("Plot saved as controlled_example_plot.png")
