# GesturePoint: Tune K Using Cross-Validation
# Compare Two Features vs Three Features

library(kknn)

# 1. Prepare the training data
# This uses only the existing training set.
# Do not use test_data for tuning.

cv_data <- train_data[, c(
  "thumb_index_distance",
  "wrist_index_distance",
  "wrist_middle_distance",
  "gesture_label"
)]

cv_data$gesture_label <- as.factor(cv_data$gesture_label)

# 2. Re-create the same five stratified folds

set.seed(123)

number_of_folds <- 5
fold_id <- integer(nrow(cv_data))

class_indices <- split(
  seq_len(nrow(cv_data)),
  cv_data$gesture_label
)

for (indices in class_indices) {
  
  shuffled_indices <- sample(indices)
  
  fold_id[shuffled_indices] <- rep(
    1:number_of_folds,
    length.out = length(shuffled_indices)
  )
}

# 3. Define a function to evaluate one value of k

evaluate_k <- function(data, features, fold_id, k_value) {
  
  fold_accuracy <- numeric(number_of_folds)
  
  for (fold in 1:number_of_folds) {
    
    validation_indices <- which(fold_id == fold)
    training_indices <- which(fold_id != fold)
    
    train_fold <- data[
      training_indices,
      c(features, "gesture_label"),
      drop = FALSE
    ]
    
    validation_fold <- data[
      validation_indices,
      c(features, "gesture_label"),
      drop = FALSE
    ]
    
    model <- kknn(
      gesture_label ~ .,
      train = train_fold,
      test = validation_fold,
      k = k_value,
      distance = 2,
      kernel = "rectangular",
      scale = TRUE
    )
    
    predictions <- as.character(fitted(model))
    actual <- as.character(validation_fold$gesture_label)
    
    fold_accuracy[fold] <- mean(
      predictions == actual
    ) * 100
  }
  
  data.frame(
    k = k_value,
    Mean_Accuracy = mean(fold_accuracy),
    SD_Accuracy = sd(fold_accuracy)
  )
}

# 4. Define the two feature sets

features_two <- c(
  "thumb_index_distance",
  "wrist_index_distance"
)

features_three <- c(
  "thumb_index_distance",
  "wrist_index_distance",
  "wrist_middle_distance"
)

# 5. Test different values of k

k_values <- c(1, 3, 5, 7, 9)

results <- data.frame()

for (k_value in k_values) {
  
  two_result <- evaluate_k(
    data = cv_data,
    features = features_two,
    fold_id = fold_id,
    k_value = k_value
  )
  
  two_result$Model <- "Two Features"
  
  three_result <- evaluate_k(
    data = cv_data,
    features = features_three,
    fold_id = fold_id,
    k_value = k_value
  )
  
  three_result$Model <- "Three Features"
  
  results <- rbind(
    results,
    two_result,
    three_result
  )
}

# 6. Display all results

results <- results[
  , c("Model", "k", "Mean_Accuracy", "SD_Accuracy")
]

print("Cross-validation results for each k:")

print(results)

# 7. Identify the best result for each feature set

best_two <- results[
  results$Model == "Two Features", 
]

best_two <- best_two[
  which.max(best_two$Mean_Accuracy),
]

best_three <- results[
  results$Model == "Three Features",
]

best_three <- best_three[
  which.max(best_three$Mean_Accuracy),
]

print("Best result: Two Features")
print(best_two)

print("Best result: Three Features")
print(best_three)
