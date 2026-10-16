
import {
  FilesetResolver,
  HandLandmarker
} from "https://cdn.jsdelivr.net/npm/@mediapipe/tasks-vision@latest/vision_bundle.mjs";

// ============================================================
// HTML ELEMENTS
// ============================================================

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
const handPointer = document.getElementById("handPointer");

// ============================================================
// KNN SETTINGS
// ============================================================

const K = 3;
const PREDICTION_WINDOW = 7;

const FEATURE_NAMES = [
  "thumb_index_distance",
  "wrist_index_distance",
  "wrist_middle_distance"
];

// ============================================================
// PINCH-TO-CLICK SETTINGS
// ============================================================

// Pinch starts below this normalized fingertip distance.
const PINCH_THRESHOLD = 0.05;

// Fingers must separate beyond this distance to rearm.
const PINCH_RELEASE_THRESHOLD = 0.08;

let clickReady = false;
let isPinching = false;

let knnTrainingData = [];
let featureMeans = [];
let featureStdDevs = [];

const predictionHistory = [];

// ============================================================
// TRAINING DATA COLLECTION
// ============================================================

const trainingData = [];

let latestThumbIndexDistance = null;
let latestWristIndexDistance = null;
let latestWristMiddleDistance = null;

// ============================================================
// LOAD TRAINING DATA FROM CSV
// ============================================================

async function loadKNNTrainingData() {
  const response = await fetch(
    "./data/gesturepoint_training_data.csv"
  );

  if (!response.ok) {
    throw new Error(
      "Could not load the GesturePoint training CSV."
    );
  }

  const csvText = await response.text();
  const lines = csvText.trim().split(/\r?\n/);

  if (lines.length < 2) {
    throw new Error("The training CSV contains no samples.");
  }

  const headers = lines[0]
    .split(",")
    .map(header => header.trim());

  const requiredHeaders = [
    ...FEATURE_NAMES,
    "gesture_label"
  ];

  for (const header of requiredHeaders) {
    if (!headers.includes(header)) {
      throw new Error(
        `Missing required CSV column: ${header}`
      );
    }
  }

  knnTrainingData = lines
    .slice(1)
    .filter(line => line.trim() !== "")
    .map(line => {
      const values = line
        .split(",")
        .map(value => value.trim());

      const sample = {};

      headers.forEach((header, index) => {
        sample[header] = values[index];
      });

      for (const feature of FEATURE_NAMES) {
        sample[feature] = Number(sample[feature]);

        if (!Number.isFinite(sample[feature])) {
          throw new Error(
            `Invalid number in CSV column: ${feature}`
          );
        }
      }

      return sample;
    });

  if (knnTrainingData.length < K) {
    throw new Error(
      "The training dataset contains fewer samples than K."
    );
  }

  const validLabels = new Set([
    "fist",
    "open_palm",
    "pinch"
  ]);

  for (const sample of knnTrainingData) {
    if (!validLabels.has(sample.gesture_label)) {
      throw new Error(
        `Unexpected gesture label: ${sample.gesture_label}`
      );
    }
  }

  // Calculate feature means.
  featureMeans = FEATURE_NAMES.map(feature => {
    const total = knnTrainingData.reduce(
      (sum, sample) => sum + sample[feature],
      0
    );

    return total / knnTrainingData.length;
  });

  // Calculate feature standard deviations.
  featureStdDevs = FEATURE_NAMES.map((feature, index) => {
    const mean = featureMeans[index];

    const squaredDifferences = knnTrainingData.reduce(
      (sum, sample) =>
        sum + (sample[feature] - mean) ** 2,
      0
    );

    const standardDeviation = Math.sqrt(
      squaredDifferences / knnTrainingData.length
    );

    return standardDeviation || 1;
  });

  console.log(
    `KNN loaded ${knnTrainingData.length} training samples.`
  );
}

// ============================================================
// STANDARDIZE FEATURE VALUES
// ============================================================

function standardize(value, featureIndex) {
  return (
    (value - featureMeans[featureIndex]) /
    featureStdDevs[featureIndex]
  );
}

// ============================================================
// KNN GESTURE PREDICTION
// ============================================================

function predictGesture(features) {
  if (knnTrainingData.length < K) {
    throw new Error("KNN training data is not loaded.");
  }

  const neighbours = knnTrainingData.map(sample => {
    let squaredDistance = 0;

    FEATURE_NAMES.forEach((feature, index) => {
      const queryValue = standardize(
        features[feature],
        index
      );

      const trainingValue = standardize(
        sample[feature],
        index
      );

      squaredDistance +=
        (queryValue - trainingValue) ** 2;
    });

    return {
      label: sample.gesture_label,
      distance: Math.sqrt(squaredDistance)
    };
  });

  neighbours.sort((a, b) => a.distance - b.distance);

  const nearestNeighbours = neighbours.slice(0, K);
  const votes = {};

  for (const neighbour of nearestNeighbours) {
    if (!votes[neighbour.label]) {
      votes[neighbour.label] = {
        count: 0,
        totalDistance: 0
      };
    }

    votes[neighbour.label].count++;

    votes[neighbour.label].totalDistance +=
      neighbour.distance;
  }

  const prediction = Object.entries(votes).sort(
    ([, a], [, b]) =>
      b.count - a.count ||
      a.totalDistance - b.totalDistance
  )[0][0];

  return {
    gesture: prediction,
    neighbours: nearestNeighbours
  };
}

// ============================================================
// TEMPORAL SMOOTHING
// ============================================================

function getStableGesture(newPrediction) {
  predictionHistory.push(newPrediction);

  if (predictionHistory.length > PREDICTION_WINDOW) {
    predictionHistory.shift();
  }

  const counts = {};

  for (const gesture of predictionHistory) {
    counts[gesture] = (counts[gesture] || 0) + 1;
  }

  let stableGesture = null;
  let highestCount = 0;

  for (const [gesture, count] of Object.entries(counts)) {
    if (count > highestCount) {
      highestCount = count;
      stableGesture = gesture;
    }
  }

  return stableGesture;
}

// ============================================================
// RECORD TRAINING SAMPLE
// ============================================================

function recordSample(gesture) {
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
}

// ============================================================
// GESTURE BUTTONS
// ============================================================

pinchButton.addEventListener("click", () => {
  recordSample("pinch");
});

fistButton.addEventListener("click", () => {
  recordSample("fist");
});

palmButton.addEventListener("click", () => {
  recordSample("open_palm");
});

// ============================================================
// DOWNLOAD COLLECTED TRAINING DATA
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

  setTimeout(() => URL.revokeObjectURL(url), 1000);

  dataStatus.textContent =
    `Downloaded ${trainingData.length} training samples.`;
});

// ============================================================
// ON-SCREEN POINTER
// ============================================================


function moveHandPointer(indexTip) {
  if (!handPointer) return;

  // Map the fingertip to the whole browser viewport.
  // Mirroring makes movement feel natural, like a selfie camera.
  const pointerX = (1 - indexTip.x) * window.innerWidth;
  const pointerY = indexTip.y * window.innerHeight;

  handPointer.style.left = `${pointerX}px`;
  handPointer.style.top = `${pointerY}px`;
  handPointer.style.display = "block";
}


function hideHandPointer() {
  if (handPointer) {
    handPointer.style.display = "none";
  }
}

// ============================================================
// PINCH-TO-CLICK
// ============================================================

function handlePinchClick(thumbTip, indexTip) {
  // Euclidean distance between thumb and index fingertips.
  const distance = Math.hypot(
    thumbTip.x - indexTip.x,
    thumbTip.y - indexTip.y
  );

  // Require the fingers to separate before another click.
  if (distance >= PINCH_RELEASE_THRESHOLD) {
    isPinching = false;
    clickReady = true;
    return;
  }

  // Trigger only once for each pinch.
  if (distance <= PINCH_THRESHOLD && clickReady && !isPinching) {
    isPinching = true;
    clickReady = false;

    if (!handPointer || handPointer.style.display === "none") {
      return;
    }

    // Find the pointer's centre in browser viewport coordinates.
    const pointerRect = handPointer.getBoundingClientRect();

    const x = pointerRect.left + pointerRect.width / 2;
    const y = pointerRect.top + pointerRect.height / 2;

    const target = document.elementFromPoint(x, y);

    if (!target) {
      console.log("Pinch detected, but no element was found.");
      return;
    }

    // Find the nearest clickable element under the pointer.
    const clickableElement = target.closest(
      [
        "button",
        "a[href]",
        "input:not([type='hidden'])",
        "select",
        "textarea",
        "[role='button']",
        "[role='link']",
        "[tabindex]:not([tabindex='-1'])"
      ].join(",")
    );

    if (clickableElement && !clickableElement.disabled) {
      clickableElement.click();

      console.log(
        "Pinch click triggered:",
        clickableElement
      );
    } else {
      console.log(
        "Pinch detected, but no clickable element is underneath the pointer."
      );
    }
  }
}

// ============================================================
// START GESTUREPOINT
// ============================================================

async function startGesturePoint() {
  let cameraStream = null;

  try {
    statusText.textContent = "Requesting camera access...";

    if (!navigator.mediaDevices?.getUserMedia) {
      throw new Error(
        "Camera access requires HTTPS or localhost."
      );
    }

    if (
      !webcam ||
      !canvas ||
      !canvasContext ||
      !statusText ||
      !handPointer ||
      !pinchButton ||
      !fistButton ||
      !palmButton ||
      !dataStatus ||
      !handSelect ||
      !downloadButton
    ) {
      throw new Error(
        "One or more required HTML elements are missing."
      );
    }

    cameraStream = await navigator.mediaDevices.getUserMedia({
      video: true,
      audio: false
    });

    webcam.srcObject = cameraStream;

    await new Promise((resolve, reject) => {
      webcam.onloadedmetadata = resolve;

      webcam.onerror = () => {
        reject(new Error("Could not load the webcam video."));
      };
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

    await loadKNNTrainingData();

    statusText.textContent =
      "Show your hand to the camera. Open your fingers to arm clicking.";

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
          const landmarks = results.landmarks[0];

          const wrist = landmarks[0];
          const thumbTip = landmarks[4];
          const indexTip = landmarks[8];
          const middleTip = landmarks[12];

          // Move the pointer first so click targeting uses its
          // latest position.
          moveHandPointer(indexTip);

          // Handle pinch-to-click independently of KNN smoothing.
          handlePinchClick(thumbTip, indexTip);

          // Feature 1: thumb-to-index fingertip distance.
          latestThumbIndexDistance = Math.sqrt(
            (thumbTip.x - indexTip.x) ** 2 +
            (thumbTip.y - indexTip.y) ** 2
          );

          // Feature 2: wrist-to-index fingertip distance.
          latestWristIndexDistance = Math.sqrt(
            (wrist.x - indexTip.x) ** 2 +
            (wrist.y - indexTip.y) ** 2
          );

          // Feature 3: wrist-to-middle fingertip distance.
          latestWristMiddleDistance = Math.sqrt(
            (wrist.x - middleTip.x) ** 2 +
            (wrist.y - middleTip.y) ** 2
          );

          const features = {
            thumb_index_distance: latestThumbIndexDistance,
            wrist_index_distance: latestWristIndexDistance,
            wrist_middle_distance: latestWristMiddleDistance
          };

          const prediction = predictGesture(features);
          const stableGesture = getStableGesture(
            prediction.gesture
          );

          // Log occasionally instead of flooding the console.
          if (
            !detectHand.lastLogTime ||
            performance.now() - detectHand.lastLogTime > 1000
          ) {
            console.log("Live features:", features);
            console.log("Raw prediction:", prediction.gesture);
            console.log("Stable prediction:", stableGesture);
            console.table(prediction.neighbours);

            detectHand.lastLogTime = performance.now();
          }

          statusText.textContent =
            `Hand detected! Gesture: ${stableGesture}` +
            (isPinching ? " | Pinching" : "");

          // Draw hand landmarks on the canvas.
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
        } else {
          latestThumbIndexDistance = null;
          latestWristIndexDistance = null;
          latestWristMiddleDistance = null;

          predictionHistory.length = 0;

          // Require the user to open their fingers again after
          // the hand is lost, preventing an accidental click.
          isPinching = false;
          clickReady = false;

          hideHandPointer();

          statusText.textContent =
            "No hand detected - show your hand";
        }
      } else {
        latestThumbIndexDistance = null;
        latestWristIndexDistance = null;
        latestWristMiddleDistance = null;

        predictionHistory.length = 0;
        isPinching = false;
        clickReady = false;

        hideHandPointer();
      }

      requestAnimationFrame(detectHand);
    }

    detectHand();
  } catch (error) {
    console.error("GesturePoint error:", error);

    if (cameraStream) {
      cameraStream.getTracks().forEach(track => track.stop());
    }

    hideHandPointer();

    statusText.textContent =
      "Setup failed. Check the browser console for details.";
  }
}

startGesturePoint();
