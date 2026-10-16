# GESTUREPOINT - 05 VISUALIZATION

library(ggplot2)

# Visualize the confusion matrix.
cm_data <- as.data.frame(confusion_matrix)

ggplot(
  cm_data,
  aes(x = Predicted, y = Actual, fill = Freq)
) +
  geom_tile(color = "white", linewidth = 1.2) +
  geom_text(aes(label = Freq), size = 7) +
  scale_fill_gradient(
    low = "white",
    high = "steelblue"
  ) +
  labs(
    title = "GesturePoint KNN Confusion Matrix",
    subtitle = "Actual gestures compared with predicted gestures",
    x = "Predicted Gesture",
    y = "Actual Gesture",
    fill = "Samples"
  ) +
  theme_minimal(base_size = 13)

# Visualize accuracy for different k values.
ggplot(
  k_results,
  aes(x = K, y = Accuracy)
) +
  geom_line() +
  geom_point(size = 3) +
  labs(
    title = "Accuracy for Different K Values",
    x = "Number of Neighbours (k)",
    y = "Test Accuracy (%)"
  ) +
  theme_minimal(base_size = 13)

# Visualize the gesture features by hand.
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
    title = "GesturePoint Feature Distribution",
    x = "Thumb-Index Distance",
    y = "Wrist-Index Distance",
    color = "Gesture",
    shape = "Hand"
  ) +
  theme_minimal(base_size = 13)
