# DragonScan v5.2.0

DragonScan is a dragon fruit inspection and sorting station built on the Raspberry Pi 5 (8 GB). It finds fruit whose peel looks normal but whose flesh has gone soft, translucent, or started to rot.

## How It Works

Each fruit goes through two scans, one after the other:

1. Radar scan: a 60 GHz FMCW radar, mounted at 45°, measures water content and flesh firmness beneath the peel.
2. Camera scan: a webcam measures peel color, size, skin texture, and the percentage of rotten peel area.

The fruit is classified as rotten and flagged for removal if any of these is true:

- The rotten peel area is at or above the threshold (15% by default).
- The internal decay index, which combines the camera and the radar (see [Analysis Details](#analysis-details)), is at or above 0.35.
- The combined defect score (65% camera rot + 35% radar decay) is at or above 18%.

Model training code is included in `core/model_trainer.py`. It uses saved captures from the `RIPE/`, `UNRIPE/`, and `ROTTEN/` folders, but it is not available from the current app screens.

## Bill of Materials

| Component | Purpose |
|---|---|
| Raspberry Pi 5 BCM2712 (8 GB) | Main controller running Raspberry Pi OS Bookworm (64-bit) |
| Raspberry Pi Active Cooler | Keeps the Pi cool during processing |
| Raspberry Pi 27W USB-C PD | Powers the Pi and connected sensors |
| Logitech C270 webcam | 720p 30 FPS camera connected via USB-A port |
| Hi-Link HLK-LD6002 60 GHz radar | Radar scanner connected via the carrier board |
| ANDAR ADTE210400XXNA01L V2.0 (20230828) USB-C Carrier Board | Radar carrier board connected via USB-C port |

## Sensor Requirements

A scan needs both the camera and the radar. The app never makes a prediction from simulated or placeholder data.

When a sensor is missing:

- The `Scan fruit` buttons are disabled and read `Scan unavailable`.
- The result card shows `Offline`, and the status line names the missing sensor (for example, "No radar connected: scanning is disabled.").
- The CAM and RADAR chips in the header turn amber.
- The camera view shows a standby screen. It is not analyzed, so no rot or size readings appear.
- The accuracy check, photo capture, quick save, and radar test refuse to run.

Both sensors reconnect on their own, without restarting the app:

- Camera: if the webcam stops sending frames for about half a second, it is treated as unplugged. The app tries to reconnect every 2.5 seconds.
- Radar: while the radar is missing, the app checks for it every 3 seconds. It probes straight away when the list of serial ports changes, and does a full probe at least every 30 seconds. A serial port counts as the radar only if it sends data within 0.5 seconds of opening. After a read error, or 3 readings in a row with no data, the radar is treated as unplugged.

If your radar takes longer than 0.5 seconds to start sending data, raise `HANDSHAKE_TIMEOUT_SEC` at the top of `hardware/radar_controller.py`.

## Quick Start

```bash
pip install -r requirements.txt
python3 main.py
```

You can also use the launch scripts: `run_dragonscan.bat` on Windows or `run_dragonscan.sh` on Linux and the Pi.

## Using the Software

The window has two pages, `Scan` and `Data`, which you switch between in the header. The header also shows CAM and RADAR status chips. The window opens in full-screen mode on screens of 800 × 480 or smaller.

The Scan page shows a camera preview and a result card. The result card shows the scan status, the rotten area percentage, the radar reading, and the `Scan fruit` button. `Settings →` opens the sensor details, the scan mode and auto-save options, and the radar spectrum.

To scan a fruit:

1. Make sure both CAM and RADAR are green. Scanning is disabled until they are (see [Sensor Requirements](#sensor-requirements)).
2. Place the fruit in the cradle and click `Scan fruit`. In `Auto-scan` mode, the scan starts on its own once the fruit has been steady for about 0.8 seconds. The default is `Manual`. Switch modes with the scan mode toggle on the result card or in Settings.
3. Wait for the radar scan (step 1 of 2) and then the camera scan (step 2 of 2).
4. Read the result in the pop-up window. It shows the verdict (Ripe, Unripe, or Rotten), the sensor readings (including internal decay and radar decay), and the current accuracy figures.
5. Remove the fruit. The station resets for the next one.

The Data page shows summary figures and charts for the saved scans, and has an `Export CSV` button.

Controls:

| Action | Result |
|---|---|
| F11 or the `Full screen` / `Exit ↗` button | Turn full-screen mode on or off |
| Esc | Leave full-screen mode |
| Double-click the video | Turn full-screen mode on or off |
| `Expand view` on the camera preview | Switch between the large camera view and the results view |

## Analysis Details

Peel color is classified by hue (OpenCV scale, 0–180):

| Class | Hue range |
|---|---|
| Ripe (magenta) | 140–180 and 0–10 |
| Bracts / scales (yellow-green) | 35–85 |
| Rot (brown to black) | 10–30, with low brightness |

Rotten percentage = (rotten pixel area ÷ total fruit area) × 100

Length and width are given in millimeters using a fixed ratio of 4.2 px/mm. Surface area is given in cm².

The radar reports a radar-only decay index (0–1). The fusion classifier (`core/fusion_classifier.py`) combines it with the camera:

Internal decay = 0.6 × radar decay + 0.4 × (rotten percentage ÷ 100)

The weights are `DECAY_WEIGHT_RADAR` and `DECAY_WEIGHT_CAMERA` in `config.py`. The rotten threshold for internal decay is `RADAR_INTERNAL_ROTTEN_THRESHOLD` (0.35), which you can also change with the "Internal Decay Threshold (camera + radar)" slider. The combined defect score uses the radar-only decay, so the camera is not counted twice.

The app also adjusts itself while it runs:

- It scales the rot threshold for small and large fruit (auto-adjust).
- It recalculates accuracy and the confusion matrix after every saved scan.

## Saved Results

While auto-save is on, every scan is saved into `RIPE/`, `UNRIPE/`, or `ROTTEN/`. Auto-save is on by default, and you can toggle it on the result card or in Settings. Each category folder contains three subfolders:

- `original/`: the raw camera photo (`<scan_id>_original.png`)
- `detection/`: the photo marked with the detection box, fruit outline, and rot areas (`<scan_id>_detection.png`)
- `json/`: the full scan record (`<scan_id>.json`)

The `fusion` block of each JSON record stores `internal_decay_index` (camera + radar), `radar_decay_index` (radar only), `is_internal_rot`, and `decay_model`. New scans are tagged `fusion_v2`. Older scans without this tag already store a combined decay value, and the accuracy tester and model trainer use that value as it is.

## Project Structure

```
dragonscan/
├── config.py                 # Hardware settings, thresholds, weights, and color ranges
├── main.py                   # App launcher
├── run_dragonscan.bat        # Windows launch script
├── run_dragonscan.sh         # Linux / Raspberry Pi launch script
├── requirements.txt          # Python dependencies
├── yolo11n.pt                # Pretrained YOLOv11 weights
├── hardware/
│   ├── camera_controller.py  # Webcam capture, standby screen, and automatic reconnect
│   └── radar_controller.py   # 60 GHz radar: radar-only decay, port check, and automatic reconnect
├── core/
│   ├── vision_analyzer.py    # Color, size, texture, and rot analysis
│   ├── yolo_detector.py      # YOLO model loader
│   ├── fusion_classifier.py  # Combines camera and radar results, including internal decay
│   ├── accuracy_tester.py    # Accuracy and confusion matrix
│   ├── dataset_manager.py    # Saves scans into category subfolders
│   ├── model_trainer.py      # Model training and evaluation
│   └── batch_scanner.py      # Batch import of a photo folder (needs a connected radar)
├── gui/
│   ├── dashboard.py          # Main app window
│   ├── splash.py             # Startup splash screen
│   ├── theme.py              # Colors, fonts, and rounded widgets
│   └── assets/               # Logo and other images
├── RIPE/
├── UNRIPE/
└── ROTTEN/
```
