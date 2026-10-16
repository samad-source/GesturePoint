# GesturePoint: 5-Fold Cross-Validation
# Comparing Two Features vs Three Features

library(kknn)

# 1. Prepare the training data
# We use train_data only.
# The separate test_data remains untouched.

cv_data <- train_data[, c(
  "thumb_index_distance",
  "wrist_index_distance",
  "wrist_middle_distance",
  "gesture_label"
)]

cv_data$gesture_label <- as.factor(cv_data$gesture_label)

# 2. Create five stratified folds

set.seed(123)

number_of_folds <- 5

fold_id <- integer(nrow(cv_data))

# Divide each gesture class across the five folds
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

# Check how many samples from each class
# appear in each fold.

print("Class distribution across folds:")

print(
  table(
    Fold = fold_id,
    Gesture = cv_data$gesture_label
  )
)

# 3. Create a function to evaluate a feature set

evaluate_cv <- function(data, features, fold_id, model_name) {
  
  fold_accuracy <- numeric(number_of_folds)
  
  for (fold in 1:number_of_folds) {
    
    # Select the validation fold
    validation_indices <- which(fold_id == fold)
    
    # Use all remaining folds for training
    training_indices <- which(fold_id != fold)
    
    # Select the relevant columns
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
    
    # Train and evaluate KNN
    model <- kknn(
      gesture_label ~ .,
      train = train_fold,
      test = validation_fold,
      k = 3,
      distance = 2,
      kernel = "rectangular",
      scale = TRUE
    )
    
    # Get predictions
    predictions <- as.character(fitted(model))
    
    actual <- as.character(
      validation_fold$gesture_label
    )
    
    # Calculate accuracy for this fold
    fold_accuracy[fold] <- mean(
      predictions == actual
    ) * 100
  }
  
  # Return the results
  data.frame(
    Model = model_name,
    Fold = 1:number_of_folds,
    Accuracy_Percent = fold_accuracy
  )
}

# 4. Evaluate Model A: two features

features_two <- c(
  "thumb_index_distance",
  "wrist_index_distance"
)

results_two <- evaluate_cv(
  data = cv_data,
  features = features_two,
  fold_id = fold_id,
  model_name = "Two Features"
)

# 5. Evaluate Model B: three features

features_three <- c(
  "thumb_index_distance",
  "wrist_index_distance",
  "wrist_middle_distance"
)

results_three <- evaluate_cv(
  data = cv_data,
  features = features_three,
  fold_id = fold_id,
  model_name = "Three Features"
)

# 6. Combine the fold results

all_results <- rbind(
  results_two,
  results_three
)

print("Accuracy for each fold:")

print(all_results)

# 7. Calculate mean and standard deviation

mean_two <- mean(results_two$Accuracy_Percent)
mean_three <- mean(results_three$Accuracy_Percent)

sd_two <- sd(results_two$Accuracy_Percent)
sd_three <- sd(results_three$Accuracy_Percent)

summary_results <- data.frame(
  Model = c("Two Features", "Three Features"),
  Mean_Accuracy = c(mean_two, mean_three),
  SD_Accuracy = c(sd_two, sd_three)
)

print("Cross-validation summary:")

print(summary_results)

# 8. Compare the mean accuracies

difference <- mean_three - mean_two

cat(
  "\nMean accuracy difference:",
  round(difference, 2),
  "percentage points\n"
)
