
import {
  FilesetResolver,
  HandLandmarker
} from "https://cdn.jsdelivr.net/npm/@mediapipe/tasks-vision@latest/vision_bundle.mjs";

const webcam = document.getElementById("webcam");
const canvas = document.getElementById("output");
const statusText = document.getElementById("status");
const canvasContext = canvas.getContext("2d");

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

            const fingertipDistance = Math.sqrt(
            (thumbTip.x - indexTip.x) ** 2 +
            (thumbTip.y - indexTip.y) ** 2
);

            const wristToIndexDistance = Math.sqrt(
              (wrist.x - indexTip.x) ** 2 +
              (wrist.y - indexTip.y) ** 2
            );

            console.log("Wrist-index distance:", wristToIndexDistance);

            console.log("Index fingertip:", {
              x: indexTip.x,
              y: indexTip.y,
              z: indexTip.z
            });

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
          statusText.textContent = "No hand detected - show your hand";
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
