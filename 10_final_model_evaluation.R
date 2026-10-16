# GesturePoint: Final Model Evaluation
# Three Features, k = 9

library(kknn)

# 1. Select the three features
features <- c(
  "thumb_index_distance",
  "wrist_index_distance",
  "wrist_middle_distance"
)

# 2. Prepare training data
final_train <- train_data[
  , c(features, "gesture_label")
]

# 3. Prepare the untouched test data
final_test <- test_data[
  , c(features, "gesture_label")
]

# Ensure the target has consistent factor levels
final_train$gesture_label <- factor(
  final_train$gesture_label
)

final_test$gesture_label <- factor(
  final_test$gesture_label,
  levels = levels(final_train$gesture_label)
)

# 4. Train the selected KNN configuration
final_model <- kknn(
  gesture_label ~ .,
  train = final_train,
  test = final_test,
  k = 9,
  distance = 2,
  kernel = "rectangular",
  scale = TRUE
)

# 5. Get predictions
final_predictions <- factor(
  as.character(fitted(final_model)),
  levels = levels(final_train$gesture_label)
)

actual <- final_test$gesture_label

# 6. Display predictions
prediction_results <- data.frame(
  Actual = actual,
  Predicted = final_predictions,
  Correct = actual == final_predictions
)

print("Final test predictions:")
print(prediction_results)

# 7. Calculate accuracy
final_accuracy <- mean(
  actual == final_predictions
) * 100

cat(
  "\nFinal test accuracy:",
  round(final_accuracy, 2),
  "%\n"
)

cat(
  "Correct predictions:",
  sum(actual == final_predictions),
  "out of",
  length(actual),
  "\n"
)

# 8. Confusion matrix
cat("\nFinal confusion matrix:\n")

print(
  table(
    Actual = actual,
    Predicted = final_predictions
  )
)
