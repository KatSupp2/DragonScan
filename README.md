# DragonScan v5.2.0

DragonScan is a dragon fruit inspection and sorting station built on the Raspberry Pi 5 (8 GB). It finds fruit whose peel looks normal but whose flesh has gone soft, translucent, or started to rot.

## How It Works

Each fruit goes through two scans, one after the other:

1. Radar scan: a 60 GHz FMCW radar, mounted at 45°, measures water content and flesh firmness beneath the peel.
2. Camera scan: a webcam measures peel color, size, skin texture, and the percentage of rotten peel area.

If the rotten area is above the threshold (15% by default) or the radar detects internal decay, the Pi triggers a GPIO actuator that pushes the fruit out of the line.

Models can also be trained inside the desktop app using saved captures from the `RIPE/`, `UNRIPE/`, and `ROTTEN/` folders.

## Bill of Materials

| Component | Purpose |
|---|---|
| Raspberry Pi 5 (8 GB) | Main controller, running Raspberry Pi OS Bookworm (64-bit) |
| Raspberry Pi Active Cooler | Keeps the Pi cool during real-time processing |
| 27 W USB-C power supply (5.1 V / 5 A) | Powers the Pi and connected sensors |
| Logitech C270 webcam | 720p, 30 FPS camera on a USB-A port (`/dev/video0`) |
| Hi-Link HLK-LD6002 60 GHz radar on ANDAR ADTE2104 V2.0 board | Subsurface scan, connected by USB-C (`/dev/ttyUSB0` or `/dev/ttyACM0`) |
| 45° sensor rig | Holds the radar at 45° and the camera 250 mm above the fruit |
| Relay and sorting actuator (GPIO 17) | Drives a solenoid or diverter arm to remove bad fruit |

## Quick Start

```bash
pip install -r requirements.txt
python3 main.py
```

## Using the Station

The app opens as a full-screen camera view. A small status panel along the bottom shows the scan progress, the verdict, the rotten area percentage, and the radar signal.

To scan a fruit:

1. Place the fruit in the cradle. The scan starts on its own after about 0.8 seconds. You can also click `CAPTURE FRUIT`.
2. Wait for the radar scan (first half of the progress dial) and the camera scan (second half).
3. Read the result in the pop-up window. It shows the verdict (Ripe, Unripe, or Rotten), the sensor readings, and the current accuracy figures.
4. Remove the fruit. The station resets for the next one.

Controls:

| Action | Result |
|---|---|
| F11 or the `FULLSCREEN` button | Turn full-screen mode on or off |
| Esc | Leave full-screen mode |
| Double-click the video | Turn full-screen mode on or off |
| `EXPAND CAMERA` button | Hide or show the status panel |

## Analysis Details

Peel color is classified by hue (OpenCV scale, 0–180):

| Class | Hue range |
|---|---|
| Ripe (magenta) | 140–180 and 0–10 |
| Bracts / scales (yellow-green) | 35–85 |
| Rot (brown to black) | 10–30, with low brightness |

Rotten percentage = (rotten pixel area ÷ total fruit area) × 100

Length and width are given in millimeters using a fixed ratio of 4.2 px/mm. Surface area is given in cm².

The app also adjusts itself while it runs:

- It corrects exposure based on the brightness of the fruit.
- It scales the rot threshold for small and large fruit.
- It compensates for radar drift.
- It recalculates accuracy and the confusion matrix after every scan.

## Saved Results

Every scan is saved automatically into `RIPE/`, `UNRIPE/`, or `ROTTEN/`. Each category folder contains three subfolders:

- `original/`: the raw camera photo (`<scan_id>_original.png`)
- `detection/`: the photo marked with the detection box, fruit outline, and rot areas (`<scan_id>_detection.png`)
- `json/`: the full scan record (`<scan_id>.json`)

## Project Structure

```
dragonfruit/
├── config.py                 # Hardware settings, thresholds, and color ranges
├── main.py                   # App launcher
├── requirements.txt          # Python dependencies
├── yolo11n.pt                # Pretrained YOLOv11 weights
├── hardware/
│   ├── camera_controller.py  # Webcam capture with simulation fallback
│   ├── radar_controller.py   # 60 GHz radar controller
│   └── gpio_sorter.py        # GPIO 17 sorting actuator
├── core/
│   ├── vision_analyzer.py    # Color, size, texture, and rot analysis
│   ├── yolo_detector.py      # YOLO model loader
│   ├── fusion_classifier.py  # Combines radar and camera results
│   ├── accuracy_tester.py    # Accuracy and confusion matrix
│   ├── dataset_manager.py    # Saves scans into category subfolders
│   └── model_trainer.py      # Model training and evaluation
├── gui/
│   └── dashboard.py          # Main app window
├── RIPE/
├── UNRIPE/
└── ROTTEN/
```