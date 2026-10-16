# GesturePoint: Feature Comparison
# Two Features vs Three Features

library(kknn)

# 1. Select the two features for Model A
train_two <- train_data[, c(
  "thumb_index_distance",
  "wrist_index_distance",
  "gesture_label"
)]

test_two <- test_data[, c(
  "thumb_index_distance",
  "wrist_index_distance",
  "gesture_label"
)]

# 2. Select all three features for Model B
train_three <- train_data[, c(
  "thumb_index_distance",
  "wrist_index_distance",
  "wrist_middle_distance",
  "gesture_label"
)]

test_three <- test_data[, c(
  "thumb_index_distance",
  "wrist_index_distance",
  "wrist_middle_distance",
  "gesture_label"
)]

# 3. Train Model A: two features
model_two <- kknn(
  gesture_label ~ .,
  train = train_two,
  test = test_two,
  k = 3,
  distance = 2,
  kernel = "rectangular",
  scale = TRUE
)

# 4. Train Model B: three features
model_three <- kknn(
  gesture_label ~ .,
  train = train_three,
  test = test_three,
  k = 3,
  distance = 2,
  kernel = "rectangular",
  scale = TRUE
)

# 5. Get predictions
pred_two <- fitted(model_two)
pred_three <- fitted(model_three)

actual <- test_data$gesture_label

# 6. Calculate accuracy
accuracy_two <- mean(pred_two == actual) * 100
accuracy_three <- mean(pred_three == actual) * 100

# 7. Compare results
comparison <- data.frame(
  Model = c("Two Features", "Three Features"),
  Features = c(2, 3),
  Correct_Predictions = c(
    sum(pred_two == actual),
    sum(pred_three == actual)
  ),
  Total_Test_Samples = length(actual),
  Accuracy_Percent = c(
    accuracy_two,
    accuracy_three
  )
)

print(comparison)

# 8. Calculate the difference in accuracy
accuracy_difference <- accuracy_three - accuracy_two

cat(
  "\nAccuracy difference (three minus two features):",
  round(accuracy_difference, 2),
  "percentage points\n"
)


# ==========================================
# 9. Compare individual predictions
# ==========================================

prediction_comparison <- data.frame(
  Test_Row = seq_along(actual),
  Actual = actual,
  Two_Feature_Prediction = as.character(pred_two),
  Three_Feature_Prediction = as.character(pred_three)
)

# Identify samples where either model was wrong
prediction_comparison$Two_Feature_Correct <-
  prediction_comparison$Actual ==
  prediction_comparison$Two_Feature_Prediction

prediction_comparison$Three_Feature_Correct <-
  prediction_comparison$Actual ==
  prediction_comparison$Three_Feature_Prediction

print(prediction_comparison)

# Show only samples where the models disagree
cat("\nSamples where the models disagree:\n")

print(
  prediction_comparison[
    prediction_comparison$Two_Feature_Prediction !=
      prediction_comparison$Three_Feature_Prediction,
  ]
)
