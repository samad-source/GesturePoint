# Load the training dataset
gesture_data <- read.csv(
  "data/gesturepoint_training_data.csv"
)

# Inspect the first six rows
head(gesture_data)

# Check the number of rows and columns
dim(gesture_data)

# Check column names and data types
str(gesture_data)

# Count samples per gesture
table(gesture_data$gesture_label)

# Count samples by gesture and hand
table(
  gesture_data$gesture_label,
  gesture_data$hand
)

# Check for missing values
colSums(is.na(gesture_data))
