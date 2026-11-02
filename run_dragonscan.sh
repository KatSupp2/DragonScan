set -e
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "$SCRIPT_DIR"

echo "========================================================"
echo "  DRAGONSCAN v5.2.0 - 7-INCH STATION CONTROLLER"
echo "  60 GHz FMCW RADAR + LOGITECH C270 HD OPTICAL SYSTEM"
echo "  Target: Raspberry Pi 5 (8GB) | Bookworm 64-bit"
echo "========================================================"

if [ -z "$DISPLAY" ]; then
    export DISPLAY=:0
fi
if [ -z "$WAYLAND_DISPLAY" ]; then
    export WAYLAND_DISPLAY=wayland-0
fi

if command -v xhost &> /dev/null; then
    xhost +local: >/dev/null 2>&1 || true
fi

if [ -d "$SCRIPT_DIR/venv" ] && [ -f "$SCRIPT_DIR/venv/bin/activate" ]; then
    echo "[INFO] Activating virtual environment (venv)..."
    source "$SCRIPT_DIR/venv/bin/activate"
    PYTHON_CMD="python3"
elif [ -d "$SCRIPT_DIR/.venv" ] && [ -f "$SCRIPT_DIR/.venv/bin/activate" ]; then
    echo "[INFO] Activating virtual environment (.venv)..."
    source "$SCRIPT_DIR/.venv/bin/activate"
    PYTHON_CMD="python3"
elif command -v python3 &> /dev/null; then
    PYTHON_CMD="python3"
else
    echo "[ERROR] python3 not found. Run: sudo apt install -y python3"
    exit 1
fi

if ! $PYTHON_CMD -c "import cv2" &> /dev/null; then
    echo "========================================================"
    echo "  [AUTO-SETUP] OpenCV (cv2) not detected."
    echo "  Configuring dedicated Raspberry Pi Python environment..."
    echo "========================================================"
    if [ ! -d "$SCRIPT_DIR/venv" ]; then
        python3 -m venv --system-site-packages "$SCRIPT_DIR/venv" || python3 -m venv "$SCRIPT_DIR/venv" || true
    fi
    if [ -f "$SCRIPT_DIR/venv/bin/activate" ]; then
        source "$SCRIPT_DIR/venv/bin/activate"
        PYTHON_CMD="$SCRIPT_DIR/venv/bin/python3"
        echo "[INFO] Installing OpenCV, NumPy, Pillow, PySerial into venv..."
        pip install opencv-python numpy pillow pyserial || true
    else
        echo "[INFO] Attempting user-space pip install..."
        pip3 install opencv-python numpy pillow pyserial --break-system-packages || true
    fi
fi

echo "[INFO] Verifying physical radar USB-serial communication..."
sudo -n chmod a+rw /dev/ttyUSB* /dev/ttyACM* 2>/dev/null || true
chmod a+rw /dev/ttyUSB* /dev/ttyACM* 2>/dev/null || true

echo "[INFO] Executing DragonScan Desktop Application..."
exec $PYTHON_CMD main.py "$@"