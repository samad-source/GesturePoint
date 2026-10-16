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
