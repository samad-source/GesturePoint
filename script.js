
import {
  FilesetResolver,
  HandLandmarker
} from "https://cdn.jsdelivr.net/npm/@mediapipe/tasks-vision@latest/vision_bundle.mjs";

const webcam = document.getElementById("webcam");
const canvas = document.getElementById("output");
const statusText = document.getElementById("status");
const canvasContext = canvas.getContext("2d");

const pinchButton = document.getElementById("pinchButton");
const fistButton = document.getElementById("fistButton");
const palmButton = document.getElementById("palmButton");
const dataStatus = document.getElementById("dataStatus");
const handSelect = document.getElementById("handSelect");
const downloadButton = document.getElementById("downloadButton");

let selectedGesture = null;

const trainingData = [];

let latestThumbIndexDistance = null;
let latestWristIndexDistance = null;

// Record one training sample
function recordSample(gesture) {
  if (
    latestThumbIndexDistance === null ||
    latestWristIndexDistance === null
  ) {
    dataStatus.textContent =
      "No hand measurements yet. Show your hand to the camera.";
    return;
  }

  const sample = {
    thumb_index_distance: latestThumbIndexDistance,
    wrist_index_distance: latestWristIndexDistance,
    gesture_label: gesture
  };

  trainingData.push(sample);

  dataStatus.textContent =
    `Collected samples: ${trainingData.length} | ` +
    `Last recorded: ${gesture}`;

  console.log("Recorded training sample:", sample);
  console.log("All training data:", trainingData);
}

// Gesture buttons
pinchButton.addEventListener("click", () => {
  selectedGesture = "pinch";
  recordSample(selectedGesture);
});

fistButton.addEventListener("click", () => {
  selectedGesture = "fist";
  recordSample(selectedGesture);
});

palmButton.addEventListener("click", () => {
  selectedGesture = "open_palm";
  recordSample(selectedGesture);
});

downloadButton.addEventListener("click", () => {
  if (trainingData.length === 0) {
    dataStatus.textContent = "No training data to download yet.";
    return;
  }

  const headers = [
    "thumb_index_distance",
    "wrist_index_distance",
    "gesture_label"
  ];

  const rows = trainingData.map(sample => [
    sample.thumb_index_distance,
    sample.wrist_index_distance,
    sample.gesture_label
  ]);

  const csvContent = [
    headers.join(","),
    ...rows.map(row => row.join(","))
  ].join("\n");

  const blob = new Blob([csvContent], {
    type: "text/csv;charset=utf-8;"
  });

  const url = URL.createObjectURL(blob);
  const link = document.createElement("a");

  link.href = url;
  link.download = "gesturepoint_training_data.csv";

  document.body.appendChild(link);
  link.click();
  document.body.removeChild(link);

  URL.revokeObjectURL(url);

  dataStatus.textContent =
    `Downloaded ${trainingData.length} training samples.`;
});

async function startGesturePoint() {
  try {
    statusText.textContent = "Requesting camera access...";

    const stream = await navigator.mediaDevices.getUserMedia({
      video: true,
      audio: false
    });

    webcam.srcObject = stream;

    await new Promise((resolve) => {
      webcam.onloadedmetadata = resolve;
    });

    await webcam.play();

    statusText.textContent = "Loading hand detection model...";

    const vision = await FilesetResolver.forVisionTasks(
      "https://cdn.jsdelivr.net/npm/@mediapipe/tasks-vision@latest/wasm"
    );

    const handLandmarker = await HandLandmarker.createFromOptions(
      vision,
      {
        baseOptions: {
          modelAssetPath:
            "https://storage.googleapis.com/mediapipe-models/hand_landmarker/hand_landmarker/float16/1/hand_landmarker.task"
        },
        runningMode: "VIDEO",
        numHands: 1
      }
    );

    canvas.width = webcam.videoWidth;
    canvas.height = webcam.videoHeight;

    statusText.textContent = "Show your hand to the camera";

    function detectHand() {
      if (webcam.readyState >= 2) {
        const results = handLandmarker.detectForVideo(
          webcam,
          performance.now()
        );

        canvasContext.clearRect(
          0,
          0,
          canvas.width,
          canvas.height
        );

        if (results.landmarks.length > 0) {
          statusText.textContent = "Hand detected!";

          for (const landmarks of results.landmarks) {
            const indexTip = landmarks[8];
            const thumbTip = landmarks[4];
            const wrist = landmarks[0];

            // Feature 1: distance between thumb and index fingertip
            const fingertipDistance = Math.sqrt(
              (thumbTip.x - indexTip.x) ** 2 +
              (thumbTip.y - indexTip.y) ** 2
            );

            latestThumbIndexDistance = fingertipDistance;

            // Feature 2: distance between wrist and index fingertip
            const wristToIndexDistance = Math.sqrt(
              (wrist.x - indexTip.x) ** 2 +
              (wrist.y - indexTip.y) ** 2
            );

            latestWristIndexDistance = wristToIndexDistance;

            // Draw hand landmarks
            for (const point of landmarks) {
              canvasContext.beginPath();

              canvasContext.arc(
                point.x * canvas.width,
                point.y * canvas.height,
                5,
                0,
                2 * Math.PI
              );

              canvasContext.fillStyle = "#00ff88";
              canvasContext.fill();
            }
          }
        } else {
          statusText.textContent =
            "No hand detected - show your hand";
        }
      }

      requestAnimationFrame(detectHand);
    }

    detectHand();
  } catch (error) {
    console.error("GesturePoint error:", error);

    statusText.textContent =
      "Setup failed. Check the browser console for details.";
  }
}

startGesturePoint();
