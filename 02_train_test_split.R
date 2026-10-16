# GESTUREPOINT - 02 TRAIN/TEST SPLIT

# Select model features and target.
model_data <- gesture_data[
  ,
  c(
    "thumb_index_distance",
    "wrist_index_distance",
    "wrist_middle_distance",
    "gesture_label"
  )
]

# KNN predicts categories, so convert the target to a factor.
model_data$gesture_label <- as.factor(
  model_data$gesture_label
)

# Make the random split reproducible.
set.seed(123)

# Group row numbers by gesture.
gesture_rows <- split(
  seq_len(nrow(model_data)),
  model_data$gesture_label
)

# Select 80% of each gesture for training.
train_index <- unlist(
  lapply(
    gesture_rows,
    function(rows) {
      sample(rows, floor(0.8 * length(rows)))
    }
  ),
  use.names = FALSE
)

# Create training and testing datasets.
train_data <- model_data[train_index, , drop = FALSE]
test_data <- model_data[-train_index, , drop = FALSE]

# Reset row names for easier inspection.
rownames(train_data) <- NULL
rownames(test_data) <- NULL

# Check the split.
cat("Training rows:", nrow(train_data), "\n")
cat("Testing rows:", nrow(test_data), "\n")

cat("\nTraining gesture counts:\n")
print(table(train_data$gesture_label))

cat("\nTesting gesture counts:\n")
print(table(test_data$gesture_label))
