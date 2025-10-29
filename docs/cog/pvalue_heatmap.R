# Function to create p-value matrix and heatmap for a given PID
# 
# Args:
#   results_list: List of JSON objects from cog2-result-db.json
#   target_pid: PID to analyze
#   target_type: "heterogeneous" or "homogeneous"
#   target_category: "collision", "energy", "length", or "time"
#
# Returns:
#   List containing:
#     - pvalue_matrix: Matrix with p-values in upper triangle
#     - plot: ggplot object of the heatmap

library(dplyr)
library(ggplot2)
library(reshape2)

create_pvalue_heatmap <- function(results_list, target_pid, target_type, target_category) {
  
  # Find the matching result
  matching_result <- NULL
  for (result in results_list) {
    # Extract PID and type from first dataset name
    dataset_name <- result$datasets[1]
    parts <- strsplit(dataset_name, "_")[[1]]
    pid <- as.numeric(parts[2])
    type <- parts[4]
    category <- result$category
    
    if (pid == target_pid && type == target_type && category == target_category) {
      matching_result <- result
      break
    }
  }
  
  if (is.null(matching_result)) {
    stop(sprintf("No data found for PID=%d, type=%s, category=%s", 
                 target_pid, target_type, target_category))
  }
  
  # Get t-test results
  ttest_df <- matching_result$t_test_results
  
  # Extract range names from subset columns
  extract_range <- function(subset_str) {
    # Extract range from "0-0.05(25421)" -> "0-0.05"
    gsub("\\(.*\\)", "", subset_str)
  }
  
  ttest_df$range1 <- sapply(ttest_df[["Subset 1(# samples)"]], extract_range)
  ttest_df$range2 <- sapply(ttest_df[["Subset 2(# samples)"]], extract_range)
  ttest_df$pvalue <- as.numeric(ttest_df[["p-value"]])
  
  # Get unique ranges in order
  all_ranges <- unique(c(ttest_df$range1, ttest_df$range2))
  
  # Sort ranges by their starting value
  range_order <- order(sapply(all_ranges, function(r) as.numeric(strsplit(r, "-")[[1]][1])))
  all_ranges <- all_ranges[range_order]
  
  n_ranges <- length(all_ranges)
  
  # Create empty matrix
  pvalue_matrix <- matrix(NA, nrow = n_ranges, ncol = n_ranges)
  rownames(pvalue_matrix) <- all_ranges
  colnames(pvalue_matrix) <- all_ranges
  
  # Fill upper triangle with p-values
  for (i in 1:nrow(ttest_df)) {
    range1 <- ttest_df$range1[i]
    range2 <- ttest_df$range2[i]
    pval <- ttest_df$pvalue[i]
    
    # Find indices
    idx1 <- which(all_ranges == range1)
    idx2 <- which(all_ranges == range2)
    
    # Put in upper triangle (row < col)
    if (idx1 < idx2) {
      pvalue_matrix[idx1, idx2] <- pval
    } else {
      pvalue_matrix[idx2, idx1] <- pval
    }
  }
  
  # Prepare data for heatmap
  melted_matrix <- melt(pvalue_matrix, na.rm = FALSE)
  colnames(melted_matrix) <- c("Range1", "Range2", "PValue")
  
  # Create heatmap
  heatmap_plot <- ggplot(melted_matrix, aes(x = Range2, y = Range1, fill = PValue)) +
    geom_tile(color = "gray80") +
    scale_fill_gradient(low = "black", high = "white", na.value = "white",
                       limits = c(0, 1), name = "P-Value") +
    geom_text(aes(label = ifelse(is.na(PValue), "", sprintf("%.3f", PValue))),
             color = "red", size = 3) +
    theme_minimal() +
    theme(axis.text.x = element_text(angle = 45, hjust = 1),
          axis.title = element_blank(),
          panel.grid = element_blank()) +
    coord_fixed() +
    labs(title = sprintf("P-Value Heatmap: PID=%d, Type=%s, Category=%s",
                        target_pid, target_type, target_category))
  
  return(list(
    pvalue_matrix = pvalue_matrix,
    plot = heatmap_plot
  ))
}


