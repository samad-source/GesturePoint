
# ============================================================
# GESTUREPOINT: KNN CLASSIFICATION PROJECT
# ============================================================
# Goal:
# Predict whether a hand is making a fist, pinch, or open palm.
#
# Current features:
# 1. thumb_index_distance
# 2. wrist_index_distance
#
# Target:
# gesture_label
# ============================================================


# ============================================================
# 1. LOAD PACKAGES
# ============================================================

library(kknn)
library(ggplot2)


# ============================================================
# 2. IMPORT THE DATASET
# ============================================================

# Make sure the CSV file is inside your project's data folder.
gesture_data <- read.csv("data/gesturepoint_training_data.csv")

# Display the first six rows.
head(gesture_data)

# Display the last six rows.
tail(gesture_data)

# Check the number of rows and columns.
dim(gesture_data)

# Check column names.
names(gesture_data)

# Check column data types.
str(gesture_data)


# ============================================================
# 3. UNDERSTAND THE DATA
# ============================================================

# Number of observations.
nrow(gesture_data)

# Number of features and other columns.
ncol(gesture_data)

# Count each gesture.
table(gesture_data$gesture_label)

# Count each gesture by hand.
table(gesture_data$hand, gesture_data$gesture_label)

# Check for missing values in each column.
colSums(is.na(gesture_data))

# Summary statistics for the numeric features.
summary(gesture_data$thumb_index_distance)
summary(gesture_data$wrist_index_distance)

# Summary of the complete dataset.
summary(gesture_data)


# ============================================================
# 4. VISUALIZE THE DATA BEFORE TRAINING
# ============================================================

# Compare the two numeric features.
ggplot(
  gesture_data,
  aes(
    x = thumb_index_distance,
    y = wrist_index_distance,
    color = gesture_label,
    shape = hand
  )
) +
  geom_point(size = 3, alpha = 0.8) +
  facet_wrap(~ hand) +
  labs(
    title = "GesturePoint: Features by Gesture and Hand",
    subtitle = "Look for clusters and overlapping observations",
    x = "Thumb-Index Distance",
    y = "Wrist-Index Distance",
    color = "Gesture",
    shape = "Hand"
  ) +
  theme_minimal(base_size = 13)


# ============================================================
# 5. PREPARE THE DATA
# ============================================================

# Keep only the two numeric features and the target label.
# We are NOT using the 'hand' column as a model predictor.
model_data <- gesture_data[
  ,
  c(
    "thumb_index_distance",
    "wrist_index_distance",
    "gesture_label"
  )
]

# Ensure the target is treated as a categorical variable.
model_data$gesture_label <- as.factor(model_data$gesture_label)

# Check the resulting dataset.
head(model_data)
str(model_data)


# ============================================================
# 6. CREATE A STRATIFIED TRAIN/TEST SPLIT
# ============================================================

# set.seed() makes the random split reproducible.
set.seed(123)

# Split row numbers into groups based on gesture.
gesture_rows <- split(
  seq_len(nrow(model_data)),
  model_data$gesture_label
)

# Select approximately 80% from each gesture for training.
train_index <- unlist(
  lapply(
    gesture_rows,
    function(rows) {
      sample(
        rows,
        size = floor(0.8 * length(rows))
      )
    }
  ),
  use.names = FALSE
)

# Create the training and testing datasets.
train_data <- model_data[train_index, ]
test_data <- model_data[-train_index, ]

# Check the sizes.
nrow(train_data)
nrow(test_data)

# Check class balance in both datasets.
table(train_data$gesture_label)
table(test_data$gesture_label)


# ============================================================
# 7. TRAIN THE KNN MODEL
# ============================================================

# k = 3 means the model considers three nearest neighbours.
#
# distance = 2 means Euclidean distance.
# kernel = "rectangular" means equal weighting.
# scale = TRUE asks kknn to scale the predictors.

gesture_model <- kknn(
  gesture_label ~ .,
  train = train_data,
  test = test_data,
  k = 3,
  distance = 2,
  kernel = "rectangular",
  scale = TRUE
)

# Extract the predicted labels.
predictions <- fitted(gesture_model)

# Compare actual labels with predicted labels.
results <- data.frame(
  Actual = test_data$gesture_label,
  Predicted = predictions
)

print(results)


# ============================================================
# 8. EVALUATE THE MODEL
# ============================================================

# Confusion matrix.
confusion_matrix <- table(
  Actual = results$Actual,
  Predicted = results$Predicted
)

print(confusion_matrix)

# Calculate accuracy.
correct_predictions <- sum(
  results$Actual == results$Predicted
)

total_predictions <- nrow(results)

accuracy <- correct_predictions / total_predictions

cat("Correct predictions:", correct_predictions, "\n")
cat("Total predictions:", total_predictions, "\n")
cat("Accuracy:", round(accuracy * 100, 2), "%\n")


# ============================================================
# 9. FIND INCORRECT PREDICTIONS
# ============================================================

# Show only rows where the model made a mistake.
misclassified <- results[
  results$Actual != results$Predicted,
  ,
  drop = FALSE
]

print(misclassified)

# Add the original row numbers and hand information.
if (nrow(misclassified) > 0) {
  
  error_rows <- as.integer(rownames(misclassified))
  
  error_details <- data.frame(
    Original_Row = error_rows,
    Hand = gesture_data$hand[error_rows],
    Actual = results$Actual[
      results$Actual != results$Predicted
    ],
    Predicted = results$Predicted[
      results$Actual != results$Predicted
    ],
    Thumb_Index_Distance =
      gesture_data$thumb_index_distance[error_rows],
    Wrist_Index_Distance =
      gesture_data$wrist_index_distance[error_rows]
  )
  
  print(error_details)
  
} else {
  
  print("No incorrect predictions in this test split.")
  
}


# ============================================================
# 10. VISUALIZE THE CONFUSION MATRIX
# ============================================================

cm_data <- as.data.frame(confusion_matrix)

ggplot(
  cm_data,
  aes(
    x = Predicted,
    y = Actual,
    fill = Freq
  )
) +
  geom_tile(color = "white", linewidth = 1.2) +
  geom_text(aes(label = Freq), size = 7) +
  scale_fill_gradient(
    low = "white",
    high = "steelblue"
  ) +
  labs(
    title = "GesturePoint KNN Confusion Matrix",
    subtitle = "Actual gestures compared with predicted gestures",
    x = "Predicted Gesture",
    y = "Actual Gesture",
    fill = "Samples"
  ) +
  theme_minimal(base_size = 13) +
  theme(
    plot.title = element_text(face = "bold")
  )


# ============================================================
# 11. COMPARE DIFFERENT DISTANCE METRICS
# ============================================================

# Euclidean distance.
model_euclidean <- kknn(
  gesture_label ~ .,
  train = train_data,
  test = test_data,
  k = 3,
  distance = 2,
  kernel = "rectangular",
  scale = TRUE
)

pred_euclidean <- fitted(model_euclidean)

accuracy_euclidean <- mean(
  pred_euclidean == test_data$gesture_label
)


# Manhattan distance.
model_manhattan <- kknn(
  gesture_label ~ .,
  train = train_data,
  test = test_data,
  k = 3,
  distance = 1,
  kernel = "rectangular",
  scale = TRUE
)

pred_manhattan <- fitted(model_manhattan)

accuracy_manhattan <- mean(
  pred_manhattan == test_data$gesture_label
)


# Compare the two results.
distance_comparison <- data.frame(
  Distance = c("Euclidean", "Manhattan"),
  Accuracy = round(
    c(accuracy_euclidean, accuracy_manhattan) * 100,
    2
  )
)

print(distance_comparison)


# ============================================================
# 12. COMPARE DIFFERENT WEIGHTING KERNELS
# ============================================================

# Equal weighting.
model_uniform <- kknn(
  gesture_label ~ .,
  train = train_data,
  test = test_data,
  k = 3,
  distance = 2,
  kernel = "rectangular",
  scale = TRUE
)

pred_uniform <- fitted(model_uniform)

accuracy_uniform <- mean(
  pred_uniform == test_data$gesture_label
)


# Triangular weighting gives closer neighbours more influence.
model_triangular <- kknn(
  gesture_label ~ .,
  train = train_data,
  test = test_data,
  k = 3,
  distance = 2,
  kernel = "triangular",
  scale = TRUE
)

pred_triangular <- fitted(model_triangular)

accuracy_triangular <- mean(
  pred_triangular == test_data$gesture_label
)


# Compare weighting methods.
weight_comparison <- data.frame(
  Kernel = c("Rectangular", "Triangular"),
  Accuracy = round(
    c(accuracy_uniform, accuracy_triangular) * 100,
    2
  )
)

print(weight_comparison)


# ============================================================
# 13. COMPARE DIFFERENT VALUES OF K
# ============================================================

k_values <- c(1, 3, 5, 7, 9)

k_results <- data.frame(
  K = integer(),
  Correct = integer(),
  Accuracy = numeric()
)

for (current_k in k_values) {
  
  current_model <- kknn(
    gesture_label ~ .,
    train = train_data,
    test = test_data,
    k = current_k,
    distance = 2,
    kernel = "rectangular",
    scale = TRUE
  )
  
  current_predictions <- fitted(current_model)
  
  current_correct <- sum(
    current_predictions == test_data$gesture_label
  )
  
  current_accuracy <- mean(
    current_predictions == test_data$gesture_label
  )
  
  k_results <- rbind(
    k_results,
    data.frame(
      K = current_k,
      Correct = current_correct,
      Accuracy = round(current_accuracy * 100, 2)
    )
  )
}

print(k_results)


# Visualize accuracy for different k values.
ggplot(
  k_results,
  aes(x = K, y = Accuracy)
) +
  geom_line() +
  geom_point(size = 3) +
  labs(
    title = "GesturePoint: Accuracy for Different K Values",
    x = "Number of Neighbours (k)",
    y = "Test Accuracy (%)"
  ) +
  theme_minimal(base_size = 13)


# ============================================================
# 14. INVESTIGATE A MISCLASSIFIED OBSERVATION
# ============================================================

# Find the first incorrect prediction, if one exists.
if (nrow(misclassified) > 0) {
  
  error_row <- as.integer(rownames(misclassified)[1])
  
  # Find its position in the test dataset.
  test_position <- match(error_row, as.integer(rownames(test_data)))
  
  sample_to_investigate <- test_data[
    test_position,
    c("thumb_index_distance", "wrist_index_distance"),
    drop = FALSE
  ]
  
  print(sample_to_investigate)
  
  # Prepare numeric feature matrices.
  train_features <- train_data[
    ,
    c("thumb_index_distance", "wrist_index_distance")
  ]
  
  sample_features <- sample_to_investigate
  
  # Standardize using training-set means and standard deviations.
  feature_means <- sapply(train_features, mean)
  feature_sds <- sapply(train_features, sd)
  
  # Protect against a feature having zero standard deviation.
  feature_sds[feature_sds == 0] <- 1
  
  train_scaled <- scale(
    train_features,
    center = feature_means,
    scale = feature_sds
  )
  
  sample_scaled <- scale(
    sample_features,
    center = feature_means,
    scale = feature_sds
  )
  
  # Calculate Euclidean distance to each training observation.
  distances <- sqrt(
    rowSums(
      (
        sweep(
          train_scaled,
          2,
          as.numeric(sample_scaled),
          "-"
        )
      )^2
    )
  )
  
  # Select the three closest training observations.
  nearest_indices <- order(distances)[
    seq_len(min(3, length(distances)))
  ]
  
  nearest_neighbors <- data.frame(
    Distance = distances[nearest_indices],
    Gesture = train_data$gesture_label[nearest_indices],
    Thumb_Index_Distance =
      train_data$thumb_index_distance[nearest_indices],
    Wrist_Index_Distance =
      train_data$wrist_index_distance[nearest_indices]
  )
  
  print(nearest_neighbors)
  
} else {
  
  print("No misclassified observation to investigate.")
  
}


# ============================================================
# 15. END OF CURRENT PRACTICE
# ============================================================

cat("GesturePoint analysis completed.\n")
