library(here)
source(here("examples", "04_trajectory_example.R"))

# Compute difference variables for plotting
same_param_diff <- trajectory_df$base_collision_times - trajectory_df$truthy_collision_times
random_param_diff <- trajectory_df$base_collision_times - trajectory_df$random_collision_times
same_param_variance <- var(same_param_diff)
random_param_variance <- var(random_param_diff)

par(mfrow=c(2,2))

# Plot 1: Delay Time vs Collision Times relationship
plot(trajectory_df$base_delay_time, trajectory_df$base_collision_times,
     main="Visual Delay Time vs Collision Times",
     xlab="Visual Perception Delay Time", ylab="Collision Times",
     pch=16, cex=0.5, col="darkblue", alpha=0.6)

# Add trend line
lm_fit <- lm(base_collision_times ~ base_delay_time, data = trajectory_df)
abline(lm_fit, col="red", lwd=2)
legend("topright", paste("R² =", round(summary(lm_fit)$r.squared, 3)), bty="n")

# Plot 2: Distribution of delay times (parameter space)
hist(trajectory_df$base_delay_time, main="Distribution of Delay Times",
     xlab="Visual Perception Delay Time", col="lightblue", breaks=30)
abline(v=mean(trajectory_df$base_delay_time), col="red", lwd=2)
legend("topright", paste("Mean =", round(mean(trajectory_df$base_delay_time), 3)), bty="n")

# Plot 3: Same parameter differences (simulation noise)
hist(same_param_diff, main="Same Parameter Differences",
     xlab="Difference in Collision Times", col="lightgreen", breaks=30)
abline(v=0, col="red", lwd=2)
abline(v=mean(same_param_diff), col="blue", lwd=2)
legend("topright", c("Zero", paste("Mean =", round(mean(same_param_diff), 2))), 
       col=c("red", "blue"), lwd=2)

# Plot 4: Variance comparison - key result
variances <- c(same_param_variance, random_param_variance)
names(variances) <- c("Same Delay", "Random Delay")
barplot(variances, main="Variance Decomposition Results",
        ylab="Variance", col=c("lightgreen", "orange"))
text(1:2, variances + max(variances)*0.05, round(variances, 2), 
     pos=3, cex=0.9)

# Add impact variance annotation
impact_var <- random_param_variance - same_param_variance
text(1.5, max(variances)*0.7, paste("Impact Variance =", round(impact_var, 2)), 
     cex=1.1, font=2, col="purple")

cat("Real trajectory analysis plots saved as trajectory_example_plot.png")
