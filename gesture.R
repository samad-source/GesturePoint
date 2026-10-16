# Two points with two features
hand_A <- c(2,3)
hand_B <- c(5,7)

# calculating the difference
diff <- hand_A - hand_B

# squared the difference
squared_diff <- diff^2

# Add the squared differences
total <- sum(squared_diff)

# Calculate the Euclidean distance
distance <- sqrt(total)

# Display the result
print(distance)

# Create example coordinates for three landmarks
hand_landmarks <- data.frame(
  landmark = c("wrist", "index_mcp", "index_tip"),
  x = c(0.30, 0.35, 0.40),
  y = c(0.70, 0.45, 0.20),
  z = c(0.00, -0.02, -0.04)
)

# Display the landmark dataset
print(hand_landmarks)

# Inspect its structure
str(hand_landmarks)

# Extract the wrist coordinates
wrist_x <- hand_landmarks$x[1]
wrist_y <- hand_landmarks$y[1]

# Calculate the index fingertip position
# relative to the wrist
hand_landmarks$relative_x <- hand_landmarks$x - wrist_x
hand_landmarks$relative_y <- hand_landmarks$y - wrist_y

# Display the transformed data
print(hand_landmarks)

# Illustrative fingertip coordinates
thumb_tip <- c(0.35, 0.40)
index_tip <- c(0.37, 0.42)

# Calculate the distance
fingertip_distance <- sqrt(
  (thumb_tip[1] - index_tip[1])^2 +
    (thumb_tip[2] - index_tip[2])^2
)

print(fingertip_distance)
