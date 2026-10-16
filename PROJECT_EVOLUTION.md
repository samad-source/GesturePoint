# GesturePoint: From Browser-Based Hand Tracking to Desktop Mouse Control

## 1. Introduction

GesturePoint began as an experiment in human-computer interaction: using hand gestures to control an on-screen pointer instead of relying entirely on a physical mouse.

The original goal was to build a system that could detect hand movements through a webcam, recognize gestures, and translate those gestures into computer interactions.

The project started as a browser-based application built with HTML, CSS, and JavaScript, using MediaPipe for hand landmark detection and a K-Nearest Neighbors (KNN) model for gesture recognition.

During development, I discovered an important distinction between controlling a pointer inside a webpage and controlling the actual mouse cursor across an operating system. That discovery became the motivation for the second project: GesturePoint Desktop.

------------------------------------------------------------------------

## 2. Project One: GesturePoint Web

### Objective

The first version aimed to demonstrate that hand movements could be translated into pointer movements and gesture-based interactions directly in a web browser.

### Technologies

-   **HTML** — application structure.
-   **CSS** — layout, styling, and custom pointer presentation.
-   **JavaScript** — application logic and webcam processing.
-   **MediaPipe Hand Landmarker** — hand landmark detection.
-   **K-Nearest Neighbors (KNN)** — gesture classification.
-   **CSV** — storage of gesture training examples.

### How it works

The application captures video from the user's webcam and processes the frames to identify hand landmarks.

It extracts selected measurements from the detected hand, including:

-   Thumb-to-index fingertip distance.
-   Wrist-to-index fingertip distance.
-   Wrist-to-middle fingertip distance.
-   Hand selection and gesture label for training data.

These measurements provide numerical features that can be used to distinguish gestures.

The KNN classifier compares the current measurements with previously collected training examples and predicts the most likely gesture.

The application also displays a custom pointer that follows the user's index finger. Pinching the thumb and index finger is intended to activate webpage controls.

### Initial gesture dataset

The initial dataset contained 90 examples across three gesture classes.

| Gesture   | Number of examples |
|-----------|-------------------:|
| Fist      |                 30 |
| Open palm |                 30 |
| Pinch     |                 30 |
| **Total** |             **90** |

The dataset included examples for both left and right hands.

An initial KNN experiment using three numerical features achieved 88.89% test accuracy on a test set of 18 examples, with 16 correct predictions.

This result was an early experiment rather than proof of general performance. A larger, more varied dataset and repeated evaluation would be needed to establish how well the model generalizes to different users, lighting conditions, and hand positions.

### What worked

The first project established several important capabilities:

1.  Webcam access and real-time video processing.
2.  Hand landmark detection using MediaPipe.
3.  Extraction of numerical features from hand landmarks.
4.  Collection and export of labeled gesture data.
5.  KNN-based gesture classification.
6.  A custom on-screen pointer that follows hand movement.

These components formed the foundation for the next stage.

### The key limitation

Although the pointer could move inside the webpage, it was not the actual Windows mouse cursor.

This limitation became apparent when considering the intended user experience. A user should ideally be able to point at desktop icons, open folders, interact with other applications, and control browser interfaces without being restricted to a custom pointer inside a webpage.

The problem was not simply a bug in the pointer's CSS or JavaScript. Ordinary webpages operate within browser security boundaries and cannot directly control the operating system's mouse cursor through standard web APIs.

This distinction changed the direction of the project.

------------------------------------------------------------------------

## 3. The Turning Point

The central question became:

**How can hand tracking and gesture recognition be connected to the operating system's actual mouse controls?**

The browser-based application had already demonstrated the perception side of the problem: detecting a hand, tracking finger positions, and identifying gestures.

The missing capability was system-level interaction.

Instead of abandoning the first project, the next step was to preserve its useful ideas and move the cursor-control responsibility into a desktop application.

This led to GesturePoint Desktop.

------------------------------------------------------------------------

## 4. Project Two: GesturePoint Desktop

### Objective

GesturePoint Desktop aims to use webcam-based hand tracking to control the actual Windows mouse cursor.

The intended interaction is:

-   Move the index finger to move the physical screen cursor.
-   Pinch the thumb and index finger to perform a click.
-   Use additional gestures for future interactions, such as dragging or scrolling.
-   Provide a reliable way to enable and disable gesture-based mouse control.

Unlike the browser version, the desktop version is designed to work across the operating system, subject to normal Windows permissions and application restrictions.

### Proposed technologies

-   **Python** — desktop application logic.
-   **OpenCV** — webcam capture and image processing.
-   **MediaPipe** — hand landmark detection.
-   **PyAutoGUI** — operating-system mouse movement and clicking.
-   **KNN** — gesture classification, where useful.
-   **VS Code** — development environment.

The exact implementation may evolve as development progresses.

### Proposed architecture

1.  Capture webcam frames.
2.  Detect hand landmarks.
3.  Identify the index fingertip and thumb fingertip.
4.  Map fingertip coordinates to screen coordinates.
5.  Smooth cursor movement to reduce jitter.
6.  Detect pinch gestures using distance thresholds.
7.  Trigger a mouse click when the pinch transition is recognized.
8.  Provide a control mechanism to pause or resume cursor control.

The cursor movement and click logic will need separate testing. Successful hand detection does not automatically guarantee accurate screen mapping or reliable clicking.

### Why PyAutoGUI?

A desktop automation library such as PyAutoGUI can issue mouse movement and click commands to the operating system. This provides a capability that a normal webpage does not have.

The desktop application can therefore connect the results of hand tracking to actual mouse events rather than drawing a simulated pointer within a webpage.

------------------------------------------------------------------------

## 5. What Carries Over from Project One?

The second project builds on the first rather than replacing the learning already completed.

| Component | Role in the desktop project |
|------------------------------------|------------------------------------|
| Gesture recognition knowledge | Helps identify pinch and other gestures. |
| KNN fundamentals | Provides a basis for experimenting with gesture classification. |
| Training dataset | Can be reused after validating feature compatibility. |
| MediaPipe landmark concepts | Help extract fingertip coordinates. |
| Threshold-based pinch detection | Can support click recognition. |
| Testing and debugging experience | Helps diagnose tracking, mapping, and interaction problems. |

One important implementation detail is that the desktop version may not need KNN to control every action. Direct fingertip tracking can handle continuous cursor movement, while a distance threshold or a classifier can identify discrete actions such as pinching.

The most appropriate method should be selected through testing rather than assuming that machine learning is necessary for every part of the system.

------------------------------------------------------------------------

## 6. Engineering Challenges to Investigate

The desktop version introduces several new challenges:

### Coordinate mapping

Webcam coordinates must be translated into screen coordinates. The mapping must account for mirroring, screen dimensions, and the usable range of hand movement.

### Cursor smoothing

Small variations in landmark positions can make the cursor jitter. Smoothing techniques can improve usability, although excessive smoothing may introduce latency.

### Reliable clicking

A click should occur once when the user performs a pinch, not repeatedly while the fingers remain together. The implementation needs clear pinch and release states.

### Safety and control

A gesture-controlled cursor can interfere with normal computer use if it remains active unexpectedly. The application should provide a pause mechanism and a reliable way to regain manual control.

### Generalization

A gesture that works for one user may not work equally well for everyone. Testing should cover different users, lighting conditions, hand positions, and camera setups.

### Platform boundaries

The application is initially intended for Windows. Some protected interfaces, elevated applications, or operating-system security screens may restrict automated interaction.

------------------------------------------------------------------------

## 7. Development Roadmap

The planned development stages are:

-   [ ] Verify the Python environment and required dependencies.
-   [ ] Capture webcam video in Python.
-   [ ] Detect hand landmarks with MediaPipe.
-   [ ] Display fingertip coordinates for debugging.
-   [ ] Move the actual Windows mouse cursor using fingertip coordinates.
-   [ ] Add cursor smoothing and coordinate calibration.
-   [ ] Implement pinch-to-click behavior.
-   [ ] Add a pause/resume mechanism.
-   [ ] Evaluate accuracy and responsiveness.
-   [ ] Integrate the existing KNN model if it improves gesture recognition.
-   [ ] Document installation, usage, limitations, and testing results.

Each stage should be tested before moving to the next. This makes it easier to isolate problems and understand how the components interact.

------------------------------------------------------------------------

## 8. Lessons Learned

The transition from GesturePoint Web to GesturePoint Desktop highlights several software engineering lessons.

**First, a visible demonstration is not the same as complete system functionality.** A pointer that follows a hand inside a webpage may look like a mouse controller, but it does not provide operating-system-wide control.

**Second, platform constraints influence architecture.** The browser version was suitable for webcam-based interaction and visual experimentation. The desktop version is better suited to actual mouse automation.

**Third, not every component requires machine learning.** Continuous cursor movement is fundamentally a coordinate-mapping problem. Gesture classification is more relevant to identifying discrete actions.

**Fourth, limitations can create new engineering opportunities.** Discovering the browser's boundary provided a clear reason to evolve the project instead of adding increasingly complicated workarounds to the wrong architecture.

------------------------------------------------------------------------

## 9. Conclusion

GesturePoint Web established the foundation: real-time hand tracking, feature extraction, gesture data collection, and KNN experimentation.

GesturePoint Desktop extends that foundation toward the original interaction goal: using hand movements to control the actual Windows mouse cursor.

Together, the two projects represent an iterative engineering journey from a browser-based proof of concept to a desktop human-computer interaction application.

The broader goal is to explore how computer vision, gesture recognition, and desktop automation can make computer interaction more accessible and intuitive.

**Project status:** GesturePoint Web has demonstrated hand tracking and custom pointer movement. GesturePoint Desktop is the planned next development stage; its desktop-control capabilities remain to be implemented and tested.
