# GESTUREPOINT - 06 ERROR ANALYSIS

if (nrow(misclassified) == 0) {
  
  cat("There are no mistakes to investigate in this test split.\n")
  
} else {
  
  # Select the three numerical features.
  feature_columns <- c(
    "thumb_index_distance",
    "wrist_index_distance",
    "wrist_middle_distance"
  )
  
  # Get the training features and labels.
  train_features <- train_data[, feature_columns]
  train_labels <- train_data$gesture_label
  
  # Calculate scaling values from training data only.
  feature_means <- sapply(train_features, mean)
  feature_sds <- sapply(train_features, sd)
  
  # Avoid division by zero.
  feature_sds[feature_sds == 0] <- 1
  
  # Standardize the training features.
  train_scaled <- scale(
    train_features,
    center = feature_means,
    scale = feature_sds
  )
  
  # Investigate every incorrect prediction.
  for (i in seq_len(nrow(misclassified))) {
    
    # Find this observation's row in the test dataset.
    test_position <- misclassified$Test_Row[i]
    
    sample_to_investigate <- test_data[
      test_position,
      feature_columns,
      drop = FALSE
    ]
    
    actual_gesture <- misclassified$Actual[i]
    predicted_gesture <- misclassified$Predicted[i]
    
    cat("\n========================================\n")
    cat("ERROR ANALYSIS: TEST ROW", test_position, "\n")
    cat("========================================\n")
    
    cat("\nFeature measurements:\n")
    print(sample_to_investigate)
    
    cat("\nActual gesture:\n")
    print(actual_gesture)
    
    cat("\nPredicted gesture:\n")
    print(predicted_gesture)
    
    # Standardize the test observation using
    # the training-set means and standard deviations.
    sample_scaled <- scale(
      sample_to_investigate,
      center = feature_means,
      scale = feature_sds
    )
    
    # Calculate standardized Euclidean distances.
    distances <- sqrt(
      rowSums(
        sweep(
          train_scaled,
          2,
          as.numeric(sample_scaled),
          FUN = "-"
        )^2
      )
    )
    
    # Find the three nearest training observations.
    nearest_indices <- order(distances)[
      seq_len(min(3, length(distances)))
    ]
    
    nearest_neighbors <- data.frame(
      Distance = distances[nearest_indices],
      Gesture = train_labels[nearest_indices],
      Thumb_Index_Distance =
        train_features$thumb_index_distance[nearest_indices],
      Wrist_Index_Distance =
        train_features$wrist_index_distance[nearest_indices],
      Wrist_Middle_Distance =
        train_features$wrist_middle_distance[nearest_indices]
    )
    
    cat("\nThree nearest training observations:\n")
    print(nearest_neighbors)
  }
}
