# DragonScan App

DragonScan is a dragon fruit inspection and sorting station built on the Raspberry Pi 5 (8 GB). It finds fruit whose peel looks normal but whose flesh has gone soft, translucent, or started to rot.

## How It Works

Each fruit goes through two scans, one after the other:

1. Radar scan: a 60 GHz FMCW radar, mounted at 45°, measures water content and flesh firmness beneath the peel.
2. Camera scan: a webcam measures peel color, size, skin texture, and the percentage of rotten peel area.

Each fruit is placed in one of three severity classes, with a confidence score:

| Class | Rule |
|---|---|
| Severely altered | Rotten peel area ≥ 15%\*, **or** internal decay ≥ 0.35, **or** combined defect score ≥ 18%. Flagged for removal. |
| Normal | Rotten peel area < 10% **and** internal decay < 0.20 |
| Slightly altered | Everything in between |

Internal decay combines the camera and the radar, and the combined defect score is 65% camera rot + 35% radar decay. See [Analysis Details](#analysis-details).

\* Auto-adjust (always on) shifts this threshold with fruit size, between 13.5% for small fruit and 16.5% for large fruit.

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
- The result card shows `Offline`, and its `Scan status` row names what is missing (`No camera`, `No radar`, or `No sensors`).
- The CAM and RADAR chips in the header turn amber.
- The camera view shows a standby screen. It is not analyzed, so no rot or size readings appear.

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

The Scan page shows:

- a camera preview, with the radar reading card below it;
- a result card, showing the severity class and confidence, the rotten area percentage, the fruit size, and the scan status;
- the `Scan fruit` button, with the auto-save and scan mode toggles and the auto-adjust indicator underneath.

`Settings →`, on the radar reading card, opens the sensor details, peel colour, the scan mode and auto-save options, and the radar spectrum.

To scan a fruit:

1. Make sure both CAM and RADAR are green. Scanning is disabled until they are (see [Sensor Requirements](#sensor-requirements)).
2. Place the fruit in the cradle and click `Scan fruit`. In `Auto-scan` mode, the scan starts on its own once the fruit has been steady for about 0.8 seconds. The default is `Manual`. Switch modes with the scan mode toggle on the result card or in Settings.
3. Wait for the radar scan and then the camera capture. The `Scan status` row shows the progress.
4. Read the result window. It shows:
   - the severity class with its confidence (for example, "Slightly altered · 72%") and the reason;
   - the sensor readings, including internal decay and radar decay;
   - the current accuracy figures, measured on the scans you have labelled yourself.
5. Optionally, record the true class with the **True label** buttons (`Normal`, `Slight`, `Severe`). This saves the scan as a human-labelled record, or relabels it if auto-save already saved it. Tick "Same fruit as the previous labelled scan" when scanning the same fruit again.
6. Close the window with `Continue`, Enter or Esc, then remove the fruit. The station resets for the next one.

The Data page shows summary figures and charts for the saved scans. It has `Export CSV` and `Refresh` buttons.

Controls:

| Action | Result |
|---|---|
| F11 or the `Full screen` / `Exit ↗` button | Turn full-screen mode on or off |
| Esc | Leave full-screen mode, or close the result window |
| Double-click the video | Turn full-screen mode on or off |
| `Expand view` on the camera preview | Switch between the large camera view and the results view |

## Analysis Details

Peel color is classified by hue (OpenCV scale, 0–180):

| Class | Hue range |
|---|---|
| Magenta peel | 140–180 and 0–10 |
| Bracts / scales (yellow-green) | 35–85 |
| Rot (brown to black) | 10–30 with low brightness, or any hue when very dark |

Rotten percentage = (rotten pixel area ÷ total fruit area) × 100

Length and width are given in millimeters using a fixed ratio of 4.2 px/mm. Surface area is given in cm².

The radar reports a radar-only decay index (0–1). The fusion classifier (`core/fusion_classifier.py`) combines it with the camera:

- Internal decay = 0.6 × radar decay + 0.4 × (rotten percentage ÷ 100)
- Combined defect score = 0.65 × rotten percentage + 0.35 × radar decay × 100

The combined defect score uses the radar-only decay, so the camera is not counted twice.

The thresholds are in `config.py`:

| Setting | Default | Meaning |
|---|---|---|
| `ROTTEN_SEGREGATION_THRESHOLD_PERCENT` | 15 | Severe peel rot |
| `RADAR_INTERNAL_ROTTEN_THRESHOLD` | 0.35 | Severe internal decay |
| `SEVERITY_SEVERE_COMPOSITE_PCT` | 18 | Severe combined defect score |
| `SEVERITY_SLIGHT_ROT_PCT` | 10 | Upper limit of peel rot for Normal |
| `SEVERITY_SLIGHT_DECAY` | 0.20 | Upper limit of internal decay for Normal |
| `DECAY_WEIGHT_RADAR`, `DECAY_WEIGHT_CAMERA` | 0.6, 0.4 | Internal decay weights |

**Confidence** shows how far the readings sit from the nearest class boundary: 50% means exactly on a boundary, rising to 99% for readings well inside the class. For example, 14.9% peel rot is Slightly altered at about 52%, because it is almost at the 15% severe boundary.

The Normal / Slightly altered boundary was raised from 5% to 10% peel rot to reduce false positives. Measured on the 79 older scans against their original labels (42 healthy, 37 rotten):

| Boundary | Healthy fruit called altered | Rotten fruit called altered |
|---|---|---|
| 5% (before) | 30 of 42 | 28 of 37 |
| 10% (now) | 9 of 42 | 21 of 37 |

No healthy fruit reaches the 15% severe threshold (the highest reads 14.4%), so nothing healthy is flagged for removal. The radar thresholds were not changed: these scans have no measured radar data.

While it runs, the app adjusts the severe peel-rot threshold to the fruit's size (auto-adjust, always on). It moves gradually towards 13.5% for small fruit (under 35 cm²) and 16.5% for large fruit (over 90 cm²), and back towards 15% otherwise. The app also recalculates accuracy after every labelled scan. Accuracy only counts scans labelled with the **True label** buttons: auto-saved scans are filed by the rules themselves, so comparing them with the rules would always score 100%.

## Saved Results

Scans are saved into `NORMAL/`, `SLIGHTLY_ALTERED/`, or `SEVERELY_ALTERED/`:

- With auto-save on (the default, toggled on the result card or in Settings), every scan is saved under its rule-based class and marked `label_source: auto`.
- The **True label** buttons save or move a scan to the class you choose and mark it `label_source: human`.

Each class folder contains three subfolders:

- `original/`: the raw camera photo (`<scan_id>_original.png`)
- `detection/`: the photo marked with the fruit outline and rot areas (`<scan_id>_detection.png`)
- `json/`: the full scan record (`<scan_id>.json`)

Each JSON record stores:

- `category`, `label_source` (human / auto), `capture_source` (station / import), and `fruit_id`, which groups repeat scans of the same fruit;
- the camera and radar readings, including `is_simulated` and `hardware_port` for the radar;
- the `fusion` block: `severity_class`, `severity_confidence`, `internal_decay_index`, `radar_decay_index`, and `decay_model`.

### Older scans

The 79 photos imported on Oct 17 (`Fruit 1`–`Fruit 79`, from the `Oct 14/` folder) were originally filed as Ripe, Unripe or Rotten. They have been re-sorted into the severity folders by their measured peel rot: 49 Normal, 17 Slightly altered and 13 Severely altered (using the 10% boundary).

- Their old folder is kept in each record as `legacy_category`.
- They are marked `label_source: auto` and `capture_source: import`.
- Their radar values were generated during the import, not measured, so they were removed and their severity is based on the camera alone.
- 35 of them have a fruit outline that spans the whole photo, so their size readings are unreliable.

The original records, before re-sorting, are in `_archive/<date>_pre_severity_migration/`.

## Labelling and Reviewing Scans

1. **Set up the station.**
   - Connect both sensors.
   - Fix the camera height and lighting, and use a plain background that isn't green or brown.
   - Calibrate `PIXELS_PER_MM` with a ruler.
2. **Scan and label.** After each scan, click the true class in the result window, and tick "Same fruit" for repeat scans. Decide internal rot after cutting the fruit open.
3. **Review:** `python tools/review_dataset.py --flagged`.
   - It lists scans worth checking: full-frame outlines, missing or simulated radar, auto labels, and labels that disagree with the rules.
   - Fix a label with `--relabel <scan_id> <CLASS>`; remove a scan with `--delete <scan_id>`.
4. **Start over (optional):** `python tools/archive_dataset.py` moves all saved scans into `_archive/<date>/`. Nothing is deleted.

## Project Structure

```
dragonscan/
├── config.py                 # Hardware settings, thresholds, severity classes, weights, and color ranges
├── main.py                   # App launcher
├── run_dragonscan.bat        # Windows launch script
├── run_dragonscan.sh         # Linux / Raspberry Pi launch script
├── requirements.txt          # Python dependencies
├── yolo11n.pt                # Pretrained YOLOv11 weights
├── Oct 14/                   # Original photos behind the 79 imported scans
├── DRAGONSCAN_ALL_80_DATASET.csv  # Older CSV export (uses the old Ripe/Unripe/Rotten labels)
├── hardware/
│   ├── camera_controller.py  # Webcam capture, standby screen, and automatic reconnect
│   └── radar_controller.py   # 60 GHz radar: radar-only decay, port check, and automatic reconnect
├── core/
│   ├── vision_analyzer.py    # Color, size, texture, and rot analysis
│   ├── yolo_detector.py      # YOLO model loader
│   ├── fusion_classifier.py  # Severity class and confidence from camera and radar
│   ├── accuracy_tester.py    # 3-class accuracy, confusion matrix, and missed-severe count
│   ├── dataset_manager.py    # Saves, relabels, and loads scans by severity class
│   └── batch_scanner.py      # Batch import of a photo folder (needs a connected radar)
├── gui/
│   ├── dashboard.py          # Main app window
│   ├── splash.py             # Startup splash screen
│   ├── theme.py              # Colors, fonts, and rounded widgets
│   └── assets/               # Logo and other images
├── tools/
│   ├── archive_dataset.py    # Move all saved scans into _archive/
│   └── review_dataset.py     # List, flag, relabel, and delete scans
├── _archive/                 # Archived scans, including the pre-severity originals
├── NORMAL/
├── SLIGHTLY_ALTERED/
└── SEVERELY_ALTERED/
```
