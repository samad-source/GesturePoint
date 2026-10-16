# GESTUREPOINT - 04 MODEL EVALUATION

# Compare actual and predicted labels.
print(results)

# Confusion matrix.
confusion_matrix <- table(
  Actual = results$Actual,
  Predicted = results$Predicted
)

print(confusion_matrix)

# Accuracy.
correct_predictions <- sum(
  results$Actual == results$Predicted
)

total_predictions <- nrow(results)

accuracy <- correct_predictions / total_predictions

cat("Correct predictions:", correct_predictions, "\n")
cat("Total predictions:", total_predictions, "\n")
cat("Accuracy:", round(accuracy * 100, 2), "%\n")

# Find mistakes.
misclassified <- results[
  results$Actual != results$Predicted,
  ,
  drop = FALSE
]

cat("\nMisclassified observations:\n")
print(misclassified)

# Per-gesture recall:
# Of all actual examples of a gesture, what fraction was found?
recall_by_gesture <- diag(confusion_matrix) /
  rowSums(confusion_matrix)

cat("\nRecall by gesture:\n")
print(round(recall_by_gesture, 3))

# Inspect the feature values of misclassified samples.

misclassified_features <- data.frame(
  Test_Row = misclassified$Test_Row,
  Actual = misclassified$Actual,
  Predicted = misclassified$Predicted,
  test_data[
    misclassified$Test_Row,
    c(
      "thumb_index_distance",
      "wrist_index_distance",
      "wrist_middle_distance"
    ),
    drop = FALSE
  ]
)

print(misclassified_features)
