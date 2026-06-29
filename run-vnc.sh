#!/usr/bin/env bash
# Lanza el contenedor de FormReturn con VNC web.
# Acceso vía navegador: http://localhost:6080/vnc.html
#
# Rutas configurables por entorno (valores por defecto entre {}):
#   FR_DIR      carpeta del HOST con los datos de FormReturn   {~/.formreturn}
#   UPLOAD_DIR  carpeta del HOST para compartir imágenes        {~/FormReturnUploads}
#   FR_IMAGE    nombre/tag de la imagen                         {formreturn:1.7.5-vnc}
#   NOVNC_PORT  puerto noVNC en el host                         {6080}
# Los puntos de montaje DENTRO del contenedor se leen de la imagen (FR_DATA_DIR /
# FR_UPLOADS_DIR, definidos en Dockerfile.vnc); se pueden forzar con
# FR_CONTAINER_DATA / FR_CONTAINER_UPLOADS.
set -euo pipefail

IMG="${FR_IMAGE:-formreturn:1.7.5-vnc}"
FR_DIR="${FR_DIR:-${HOME}/.formreturn}"
UPLOAD_DIR="${UPLOAD_DIR:-${HOME}/FormReturnUploads}"
NOVNC_PORT="${NOVNC_PORT:-6080}"

mkdir -p "${FR_DIR}" "${UPLOAD_DIR}"
echo "Datos (host):   ${FR_DIR}"
echo "Uploads (host): ${UPLOAD_DIR}"

echo "Construyendo imagen ${IMG}..."
docker build -f Dockerfile.vnc -t "${IMG}" .

# Puntos de montaje dentro del contenedor: fuente de verdad = la imagen (Dockerfile).
img_env() {
    docker image inspect "${IMG}" --format "{{range .Config.Env}}{{println .}}{{end}}" \
        2>/dev/null | sed -n "s/^$1=//p" | head -n1 || true
}
FR_CONTAINER_DATA="${FR_CONTAINER_DATA:-$(img_env FR_DATA_DIR)}"
FR_CONTAINER_DATA="${FR_CONTAINER_DATA:-/home/ubuntu/.formreturn}"
FR_CONTAINER_UPLOADS="${FR_CONTAINER_UPLOADS:-$(img_env FR_UPLOADS_DIR)}"
FR_CONTAINER_UPLOADS="${FR_CONTAINER_UPLOADS:-/home/ubuntu/Uploads}"

echo "Iniciando contenedor..."
docker run --rm -it \
    --security-opt label=disable \
    -e "JAVA_MEM=${JAVA_MEM:-1024}" \
    -e "NOVNC_PORT=${NOVNC_PORT}" \
    -p "${NOVNC_PORT}:6080" \
    -v "${FR_DIR}:${FR_CONTAINER_DATA}" \
    -v "${UPLOAD_DIR}:${FR_CONTAINER_UPLOADS}" \
    --name formreturn \
    "${IMG}" "$@"
