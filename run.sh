#!/usr/bin/env bash
# Lanza el contenedor de FormReturn conectándose a tu pantalla X (XWayland).
# Los datos se guardan en ~/.formreturn (igual que una instalación nativa) y,
# al correr con tu UID, los archivos son tuyos (no de root).
#
# Rutas configurables por entorno (valores por defecto entre {}):
#   FR_DIR    carpeta del HOST con los datos de FormReturn   {~/.formreturn}
#   FR_IMAGE  nombre/tag de la imagen                         {formreturn:1.7.5}
# El punto de montaje DENTRO del contenedor se lee de la imagen (FR_DATA_DIR,
# definido en Dockerfile); se puede forzar con FR_CONTAINER_DATA.
set -euo pipefail

IMG="${FR_IMAGE:-formreturn:1.7.5}"
FR_DIR="${FR_DIR:-${HOME}/.formreturn}"

mkdir -p "${FR_DIR}"
echo "Datos (host): ${FR_DIR}"

# Punto de montaje dentro del contenedor: fuente de verdad = la imagen (Dockerfile).
img_env() {
    docker image inspect "${IMG}" --format "{{range .Config.Env}}{{println .}}{{end}}" \
        2>/dev/null | sed -n "s/^$1=//p" | head -n1 || true
}
FR_CONTAINER_DATA="${FR_CONTAINER_DATA:-$(img_env FR_DATA_DIR)}"
FR_CONTAINER_DATA="${FR_CONTAINER_DATA:-/home/ubuntu/.formreturn}"

# El contenedor corre con tu uid (usuario ubuntu) -> SO_PEERCRED ve a tu usuario
# del host. Autoriza a $(whoami). Revocable con:
#   xhost -SI:localuser:$(whoami)
if command -v xhost >/dev/null 2>&1; then
    xhost +SI:localuser:"$(whoami)" >/dev/null 2>&1 || xhost +local:root >/dev/null 2>&1 || true
fi

docker run --rm -it \
    --security-opt label=disable \
    --ipc=host \
    -e "DISPLAY=${DISPLAY:-:1}" \
    -v /tmp/.X11-unix:/tmp/.X11-unix:ro \
    -v "${FR_DIR}:${FR_CONTAINER_DATA}" \
    -e "JAVA_MEM=${JAVA_MEM:-1024}" \
    --name formreturn \
    "${IMG}" "$@"
