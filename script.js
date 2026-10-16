
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
let latestWristMiddleDistance = null;


// ============================================================
// RECORD ONE TRAINING SAMPLE
// ============================================================

function recordSample(gesture) {
  // Do not record if the camera has no valid measurements.
  if (
    latestThumbIndexDistance === null ||
    latestWristIndexDistance === null ||
    latestWristMiddleDistance === null
  ) {
    dataStatus.textContent =
      "No valid hand measurements. Show your hand to the camera.";

    return;
  }

  const sample = {
    thumb_index_distance: latestThumbIndexDistance,
    wrist_index_distance: latestWristIndexDistance,
    wrist_middle_distance: latestWristMiddleDistance,
    hand: handSelect.value,
    gesture_label: gesture
  };

  trainingData.push(sample);

  dataStatus.textContent =
    `Collected samples: ${trainingData.length} | ` +
    `Last recorded: ${gesture}`;

  console.log("Recorded training sample:", sample);
  console.log("All training data:", trainingData);
}


// ============================================================
// GESTURE BUTTONS
// ============================================================

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


// ============================================================
// DOWNLOAD TRAINING DATA AS CSV
// ============================================================

downloadButton.addEventListener("click", () => {
  if (trainingData.length === 0) {
    dataStatus.textContent =
      "No training data to download yet.";

    return;
  }

  const headers = [
    "thumb_index_distance",
    "wrist_index_distance",
    "wrist_middle_distance",
    "hand",
    "gesture_label"
  ];

  const rows = trainingData.map(sample => [
    sample.thumb_index_distance,
    sample.wrist_index_distance,
    sample.wrist_middle_distance,
    sample.hand,
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

  // Release the temporary URL after the download has started.
  setTimeout(() => URL.revokeObjectURL(url), 1000);

  dataStatus.textContent =
    `Downloaded ${trainingData.length} training samples.`;
});


// ============================================================
// START GESTUREPOINT
// ============================================================

async function startGesturePoint() {
  try {
    statusText.textContent = "Requesting camera access...";

    const stream = await navigator.mediaDevices.getUserMedia({
      video: true,
      audio: false
    });

    webcam.srcObject = stream;

    await new Promise(resolve => {
      webcam.onloadedmetadata = resolve;
    });

    await webcam.play();

    statusText.textContent =
      "Loading hand detection model...";

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

    statusText.textContent =
      "Show your hand to the camera";

    // ========================================================
    // DETECT HAND AND CALCULATE FEATURES
    // ========================================================

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
            // MediaPipe hand landmark positions.
            const wrist = landmarks[0];
            const thumbTip = landmarks[4];
            const indexTip = landmarks[8];
            const middleTip = landmarks[12];

            // Feature 1:
            // Distance between thumb and index fingertip.
            const fingertipDistance = Math.sqrt(
              (thumbTip.x - indexTip.x) ** 2 +
              (thumbTip.y - indexTip.y) ** 2
            );

            latestThumbIndexDistance = fingertipDistance;

            // Feature 2:
            // Distance between wrist and index fingertip.
            const wristToIndexDistance = Math.sqrt(
              (wrist.x - indexTip.x) ** 2 +
              (wrist.y - indexTip.y) ** 2
            );

            latestWristIndexDistance = wristToIndexDistance;

            // Feature 3:
            // Distance between wrist and middle fingertip.
            const wristToMiddleDistance = Math.sqrt(
              (wrist.x - middleTip.x) ** 2 +
              (wrist.y - middleTip.y) ** 2
            );

            latestWristMiddleDistance =
              wristToMiddleDistance;

            // Draw the detected hand landmarks.
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
          // Reset measurements so an old frame cannot be recorded.
          latestThumbIndexDistance = null;
          latestWristIndexDistance = null;
          latestWristMiddleDistance = null;

          statusText.textContent =
            "No hand detected - show your hand";
        }
      } else {
        // No usable video frame: measurements are not valid.
        latestThumbIndexDistance = null;
        latestWristIndexDistance = null;
        latestWristMiddleDistance = null;
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
