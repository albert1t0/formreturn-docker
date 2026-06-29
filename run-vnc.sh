#!/usr/bin/env bash
# Lanza el contenedor de FormReturn con VNC web.
# Acceso vía navegador: http://localhost:6080/vnc.html
set -euo pipefail

IMG="formreturn:1.7.5-vnc"
FR_DIR="${HOME}/.formreturn"
UPLOAD_DIR="${HOME}/FormReturnUploads"
NOVNC_PORT="${NOVNC_PORT:-6080}"

mkdir -p "${FR_DIR}"
mkdir -p "${UPLOAD_DIR}"
echo "Directorio compartido para archivos: ${UPLOAD_DIR}"

echo "Construyendo imagen ${IMG}..."
docker build -f Dockerfile.vnc -t "${IMG}" .

echo "Iniciando contenedor..."
docker run --rm -it \
    --security-opt label=disable \
    -e "JAVA_MEM=${JAVA_MEM:-1024}" \
    -e "NOVNC_PORT=${NOVNC_PORT}" \
    -p "${NOVNC_PORT}:6080" \
    -v "${FR_DIR}:/home/ubuntu/.formreturn" \
    -v "${UPLOAD_DIR}:/home/ubuntu/Uploads" \
    --name formreturn \
    "${IMG}" "$@"
