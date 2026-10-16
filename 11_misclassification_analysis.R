
# 1. Identify the incorrectly classified samples

misclassified <- actual != final_predictions

# 2. Extract the rows where the model made mistakes

error_data <- final_test[misclassified, ]

# 3. Display actual and predicted labels

error_data$Actual <- actual[misclassified]
error_data$Predicted <- final_predictions[misclassified]

print("Misclassified samples:")
print(error_data)

# 4. Compare the feature measurements of errors

features <- c(
  "thumb_index_distance",
  "wrist_index_distance",
  "wrist_middle_distance"
)

print("Feature measurements for misclassified samples:")
print(error_data[, features])


# 5. Compare feature measurements by actual gesture

print("Feature averages in the training data:")

aggregate(
  final_train[, features],
  by = list(Gesture = final_train$gesture_label),
  FUN = mean
)

print("Feature ranges in the training data:")

aggregate(
  final_train[, features],
  by = list(Gesture = final_train$gesture_label),
  FUN = function(x) {
    paste(
      round(min(x), 4),
      "to",
      round(max(x), 4)
    )
  }
)


library(ggplot2)

ggplot(
  final_train,
  aes(
    x = thumb_index_distance,
    y = wrist_middle_distance,
    color = gesture_label
  )
) +
  geom_point(size = 3, alpha = 0.8) +
  labs(
    title = "GesturePoint: Feature Overlap",
    x = "Thumb–Index Distance",
    y = "Wrist–Middle Distance",
    color = "Actual Gesture"
  ) +
  theme_minimal()

ggplot(
  final_train,
  aes(
    x = thumb_index_distance,
    y = wrist_index_distance,
    color = gesture_label
  )
) +
  geom_point(size = 3, alpha = 0.8) +
  labs(
    title = "GesturePoint: Second Feature Comparison",
    x = "Thumb–Index Distance",
    y = "Wrist–Index Distance",
    color = "Gesture"
  ) +
  theme_minimal()
