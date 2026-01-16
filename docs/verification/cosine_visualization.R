library(here)
source(here("examples", "03_sinusoidal_example.R"))

# Compute difference variables and correlation for plotting
same_param_differences <- sinusoidal_df$base_h - sinusoidal_df$truthy_h
random_param_differences <- sinusoidal_df$base_h - sinusoidal_df$random_h
same_param_variance <- var(same_param_differences)
random_param_variance <- var(random_param_differences)
correlation <- cor(sinusoidal_df$base_params, sinusoidal_df$base_h)

par(mfrow=c(2,2))

# Plot 1: Parameter vs Measurement - reveals the cosine relationship
plot(sinusoidal_df$base_params, sinusoidal_df$base_h, 
     main="Parameter vs Measurement\n(Cosine Relationship)", 
     xlab="Parameter X (radians)", ylab="Measurement H",
     pch=16, cex=0.5, col="darkblue")

# Add true cosine curve
x_curve <- seq(min(sinusoidal_df$base_params), max(sinusoidal_df$base_params), length.out=100)
y_curve <- cos(x_curve)
lines(x_curve, y_curve, col="red", lwd=3)
legend("topright", c("Data", "True: H = cos(X)"), col=c("darkblue", "red"), 
       pch=c(16, NA), lty=c(NA, 1), lwd=c(1, 3))

# Add correlation annotation
text(max(sinusoidal_df$base_params)*0.1, max(sinusoidal_df$base_h)*0.8, 
     paste("r =", round(correlation, 3)), 
     cex=1.2, font=2, col="purple", bg="white")

# Plot 2: Same parameter differences (pure noise)
plot(1:length(same_param_differences), same_param_differences,
     main="Same Parameter Differences\n(Measurement Noise Only)", 
     xlab="Sample", ylab="H - H' (same X)",
     pch=16, cex=0.5, col="green")
abline(h=0, col="black", lwd=2)

# Plot 3: Random parameter differences (noise + signal variation)
plot(1:length(random_param_differences), random_param_differences,
     main="Random Parameter Differences\n(Noise + Parameter Effect)", 
     xlab="Sample", ylab="H(X) - H'(X')",
     pch=16, cex=0.5, col="orange")
abline(h=0, col="black", lwd=2)

# Plot 4: Variance comparison - the key insight
variances <- c(same_param_variance, random_param_variance)
names(variances) <- c("Same Param\n(Noise)", "Random Param\n(Noise + Signal)")
barplot(variances, main="Variance Decomposition Results",
        ylab="Variance", col=c("green", "orange"))
text(1:2, variances + max(variances)*0.05, round(variances, 2), 
     pos=3, cex=0.9)

# Add impact variance annotation
impact_var <- random_param_variance - same_param_variance
text(1.5, max(variances)*0.7, paste("Impact Variance =", round(impact_var, 2)), 
     cex=1.1, font=2, col="purple")

cat("Cosine analysis plots saved as cosine_example_plot.png")
