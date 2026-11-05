from pathlib import Path
BASE_DIR = Path(__file__).resolve().parent
# Severity classes (dataset folder name == class key)
SEVERITY_CLASSES = ("NORMAL", "SLIGHTLY_ALTERED", "SEVERELY_ALTERED")
SEVERITY_DISPLAY = {"NORMAL": "Normal", "SLIGHTLY_ALTERED": "Slightly altered", "SEVERELY_ALTERED": "Severely altered"}
DATASET_NORMAL_DIR = BASE_DIR / "NORMAL"
DATASET_SLIGHTLY_ALTERED_DIR = BASE_DIR / "SLIGHTLY_ALTERED"
DATASET_SEVERELY_ALTERED_DIR = BASE_DIR / "SEVERELY_ALTERED"
DATASET_DIRS = {
    "NORMAL": DATASET_NORMAL_DIR,
    "SLIGHTLY_ALTERED": DATASET_SLIGHTLY_ALTERED_DIR,
    "SEVERELY_ALTERED": DATASET_SEVERELY_ALTERED_DIR,
}
ARCHIVE_DIR = BASE_DIR / "_archive"
for _d in DATASET_DIRS.values():
    _d.mkdir(parents=True, exist_ok=True)
APP_NAME = "DragonScan App"
APP_VERSION = "5.2.0-SOVEREIGN"
CAMERA_MODEL = "Logitech C270 HD Webcam (USB)"
CAMERA_WIDTH = 1280
CAMERA_HEIGHT = 720
CAMERA_FPS = 30
CAMERA_INDEX = 0                                                                               
CAMERA_FOURCC = "MJPG"                                                              
CAMERA_EXPOSURE_LOCKED = True
CAMERA_WHITE_BALANCE_LOCKED = True
USE_YOLO_IF_AVAILABLE = False
YOLO_MODEL_NAME = "yolo11n.pt"                                                     
YOLO_CONFIDENCE_THRESHOLD = 0.35
AUTO_SCAN_ON_STARTUP = False                                                                                  
AUTO_SAVE_ON_STARTUP = True                                                                
SHOW_BOUNDING_BOXES = False                                                                   
SHOW_YOLO_BOX = False                                                                       
SHOW_DEFECT_BOXES = False                                                                            
SHOW_TARGET_RETICLES = False                                                                          
SHOW_HUD_BOX = False                                                                                
SHOW_CROSSHAIR = False                                                                     
RADAR_SENSOR_MODEL = "HLK-LD6002 (VERC V1.0)"                                                              
RADAR_CARRIER_BOARD = "ANDAR ADTE210400XXNA01L V2.0"                                                 
RADAR_AUTO_ANGLE_DETECTION = True                                                                                                       
RADAR_DEFAULT_ANGLE_DEGREES = 45.0                                                         
RADAR_ANGLE_DEGREES = 45.0                            
RADAR_FREQUENCY_GHZ = 60.0
RADAR_NUM_CHIRPS = 64
RADAR_SAMPLES_PER_CHIRP = 128
RADAR_BANDWIDTH_MHZ = 4000.0                                     
RADAR_PORT = "/dev/ttyUSB0"                                                                                             
RADAR_BAUDRATE = 115200                                                                        
RADAR_TIMEOUT_SEC = 2.0
RADAR_SIMULATION_MODE = False                                                                                            
PIXELS_PER_MM = 4.2
ROTTEN_SEGREGATION_THRESHOLD_PERCENT = 15.0                                                                   
RADAR_INTERNAL_ROTTEN_THRESHOLD = 0.35                                                          
WEIGHT_VISION = 0.65
WEIGHT_RADAR = 0.35
# Internal decay = DECAY_WEIGHT_RADAR * radar decay + DECAY_WEIGHT_CAMERA * camera rotten fraction (blended in FusionClassifier)
DECAY_WEIGHT_RADAR = 0.6
DECAY_WEIGHT_CAMERA = 0.4
# Severity thresholds. Severe: rot >= SEVERE_ROT (ROTTEN_SEGREGATION_THRESHOLD_PERCENT, slider-adjustable)
# or internal decay >= SEVERE_DECAY (RADAR_INTERNAL_ROTTEN_THRESHOLD) or composite >= SEVERE_COMPOSITE.
# Normal: rot < SLIGHT_ROT and internal decay < SLIGHT_DECAY. Everything else: slightly altered.
# Tuned 2026-11-03 on the 79 imported scans (reference labels: 42 healthy, 37 rotten) to cut false
# positives: at 5% 30/42 healthy fruit read as altered; at 10% 9/42 (rotten caught 28/37 -> 21/37).
SEVERITY_SLIGHT_ROT_PCT = 10.0
SEVERITY_SLIGHT_DECAY = 0.20
SEVERITY_SEVERE_COMPOSITE_PCT = 18.0
RIPE_COLOR_LOWER = (140, 50, 50)
RIPE_COLOR_UPPER = (179, 255, 255)
RIPE_COLOR_LOWER_SECONDARY = (0, 70, 70)                      
RIPE_COLOR_UPPER_SECONDARY = (10, 255, 255)
BRACT_COLOR_LOWER = (35, 40, 40)
BRACT_COLOR_UPPER = (85, 255, 255)
ROT_COLOR_LOWER_1 = (10, 50, 20)
ROT_COLOR_UPPER_1 = (30, 200, 100)                                   
ROT_COLOR_LOWER_2 = (0, 0, 10)
ROT_COLOR_UPPER_2 = (180, 255, 65)                                       
