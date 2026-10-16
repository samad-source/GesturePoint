# GESTUREPOINT - 01 DATA EXPLORATION

library(ggplot2)

# Import the CSV file.
gesture_data <- read.csv(
  "data/gesturepoint_training_data.csv",
  stringsAsFactors = FALSE
)

# Inspect the dataset.
head(gesture_data)
tail(gesture_data)
dim(gesture_data)
names(gesture_data)
str(gesture_data)
summary(gesture_data)

# Count each gesture.
print(table(gesture_data$gesture_label))

# Count gestures by hand.
print(table(gesture_data$hand, gesture_data$gesture_label))

# Check missing values.
print(colSums(is.na(gesture_data)))

# Validate the columns expected from the updated JavaScript.
required_columns <- c(
  "thumb_index_distance",
  "wrist_index_distance",
  "wrist_middle_distance",
  "hand",
  "gesture_label"
)

missing_columns <- setdiff(required_columns, names(gesture_data))

if (length(missing_columns) > 0) {
  stop(
    "Missing columns in CSV: ",
    paste(missing_columns, collapse = ", "),
    ". Collect and download data using the updated script.js first."
  )
}

# Plot the three gesture classes.
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
    title = "GesturePoint: Feature Exploration",
    x = "Thumb-Index Distance",
    y = "Wrist-Index Distance",
    color = "Gesture",
    shape = "Hand"
  ) +
  theme_minimal(base_size = 13)
