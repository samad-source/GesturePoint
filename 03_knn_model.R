# GESTUREPOINT - 03 KNN MODEL

library(kknn)

# Baseline model: k = 3, Euclidean, equal weighting.
gesture_model <- kknn(
  gesture_label ~ .,
  train = train_data,
  test = test_data,
  k = 3,
  distance = 2,
  kernel = "rectangular",
  scale = TRUE
)

# Save predictions for later evaluation.
results <- data.frame(
  Test_Row = seq_len(nrow(test_data)),
  Actual = test_data$gesture_label,
  Predicted = fitted(gesture_model)
)

print(results)

# Compare different values of k.
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
  
  k_results <- rbind(
    k_results,
    data.frame(
      K = current_k,
      Correct = sum(
        current_predictions == test_data$gesture_label
      ),
      Accuracy = mean(
        current_predictions == test_data$gesture_label
      ) * 100
    )
  )
}

print(k_results)

# Compare Euclidean and Manhattan distances.
distance_results <- data.frame(
  Distance = c("Euclidean", "Manhattan"),
  Accuracy = numeric(2)
)

for (i in seq_len(nrow(distance_results))) {
  
  distance_value <- if (i == 1) 2 else 1
  
  distance_model <- kknn(
    gesture_label ~ .,
    train = train_data,
    test = test_data,
    k = 3,
    distance = distance_value,
    kernel = "rectangular",
    scale = TRUE
  )
  
  distance_results$Accuracy[i] <- mean(
    fitted(distance_model) == test_data$gesture_label
  ) * 100
}

print(distance_results)

# Compare equal weighting with triangular weighting.
kernel_results <- data.frame(
  Kernel = c("rectangular", "triangular"),
  Accuracy = numeric(2)
)

for (i in seq_len(nrow(kernel_results))) {
  
  kernel_model <- kknn(
    gesture_label ~ .,
    train = train_data,
    test = test_data,
    k = 3,
    distance = 2,
    kernel = kernel_results$Kernel[i],
    scale = TRUE
  )
  
  kernel_results$Accuracy[i] <- mean(
    fitted(kernel_model) == test_data$gesture_label
  ) * 100
}

print(kernel_results)
