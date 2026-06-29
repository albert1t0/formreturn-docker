#!/usr/bin/env bash
# Arranca FormReturn con VNC web (noVNC).
set -euo pipefail

FR_HOME="${FR_HOME:-/opt/formreturn}"
JAVA_MEM="${JAVA_MEM:-1024}"
DISPLAY="${DISPLAY:-:1}"
VNC_PORT="${VNC_PORT:-5900}"
NOVNC_PORT="${NOVNC_PORT:-6080}"

cd "${FR_HOME}"

# Directorio para Xvfb (en HOME del usuario para permisos)
XVFB_DIR="/home/ubuntu/.xvfb"
mkdir -p "${XVFB_DIR}"

# Iniciar Xvfb (servidor X virtual)
echo "Iniciando Xvfb en ${DISPLAY}..."
Xvfb "${DISPLAY}" -screen 0 1280x720x24 -ac -nolisten tcp +extension GLX +render -noreset &
XVFB_PID=$!
sleep 2

# Verificar que Xvfb esté corriendo
if ! kill -0 "$XVFB_PID" 2>/dev/null; then
    echo "ERROR: Xvfb falló al iniciar"
    exit 1
fi

# Iniciar window manager (fluxbox)
echo "Iniciando Fluxbox..."
DISPLAY="${DISPLAY}" fluxbox &
FLUXBOX_PID=$!
sleep 1

# Iniciar x11vnc (servidor VNC)
echo "Iniciando x11vnc en puerto ${VNC_PORT}..."
x11vnc -display "${DISPLAY}" -rfbport "${VNC_PORT}" -forever -shared -nopw -xkb -bg -q &
X11VNC_PID=$!
sleep 1

# Iniciar websockify para noVNC
echo "Iniciando websockify en puerto ${NOVNC_PORT}..."
websockify --web=/opt/novnc/noVNC "${NOVNC_PORT}" localhost:"${VNC_PORT}" &
WEBSOCKIFY_PID=$!
sleep 1

echo "=========================================="
echo "VNC web iniciado:"
echo "  http://localhost:${NOVNC_PORT}/vnc.html"
echo "=========================================="

# Función de limpieza
cleanup() {
    echo "Deteniendo servicios..."
    kill -TERM "$WEBSOCKIFY_PID" "$X11VNC_PID" "$FLUXBOX_PID" "$XVFB_PID" 2>/dev/null || true
    wait
}
trap cleanup EXIT TERM INT

# Iniciar FormReturn Manager
echo "Iniciando FormReturn Manager..."
DISPLAY="${DISPLAY}" exec java \
    -Djava.awt.headless=false \
    -Dsun.java2d.xrender=false \
    -Xmx${JAVA_MEM}m \
    -jar "${FR_HOME}/lib/formreturn.jar" \
    "$@"
